Dir[File.dirname(__FILE__)+"/videoreg/*.rb"].each { |f| require f }
require 'rubygems'
require 'logger'
require 'ostruct'
require 'amqp'
require 'json'
require_relative './videoreg/util'

####################################################
# Main videoreg module
module Videoreg

  VERSION = "0.1"
  DAEMON_NAME = "videoreg"
  MAX_THREAD_WAIT_LIMIT_SEC = 30

  ALLOWED_CONFIG_OPTIONS = %w[mq_host mq_queue pid_path log_path device]

  MSG_HALT = 'HALT'
  MSG_RECOVER = 'RECOVER'

  @registered_regs = {}
  @run_options = OpenStruct.new(
      :device => :all,
      :action => :run,
      :log_path => 'videoreg.log',
      :pid_path => '/tmp/videoreg.pid',
      :mq_host => '127.0.0.1',
      :mq_queue => 'ifree.videoreg.server'
  )

  class << self
    # Disconnect from RabbitMQ
    def mq_disconnect(connection)
      logger.info "Disconnecting from RabbitMQ..."
      connection.close { EM.stop { exit } }
    end

    # Listen the incoming messages from RabbitMQ
    def mq_listen(&block)
      Thread.start {
        logger.info "New messaging thread created for RabbitMQ #{opt.mq_host} / #{opt.mq_queue}"
        AMQP.start(:host => opt.mq_host) do |connection|
          q = AMQP::Channel.new(connection).queue(opt.mq_queue)
          q.subscribe do |msg|
            Videoreg::Base.logger.info "Received message from RabbitMQ #{msg}..."
            block.call(connection, msg) if block_given?
          end
          Signal.add_trap("TERM") { q.delete; mq_disconnect(connection)  }
          Signal.add_trap(0) { q.delete; mq_disconnect(connection)  }
        end
      }
    end

    # Send a message to the RabbitMQ
    def mq_send(message, arg = nil)
      AMQP.start(:host => opt.mq_host) do |connection|
        channel = AMQP::Channel.new(connection)
        logger.info "Publish message to RabbitMQ '#{message}' with arg '#{arg}' to '#{opt.mq_queue}'..."
        channel.default_exchange.publish({:msg => message, :arg => arg}.to_json, :routing_key => opt.mq_queue)
        EM.add_timer(0.5) { mq_disconnect(connection) }
      end
    end

    def run_options
      @run_options
    end

    def registrars
      @registered_regs
    end

    def logger
      Videoreg::Base.logger
    end


    ####################################################
    # Options
    def opt(*args)
      if !args.empty? && args[0].is_a?(Hash)
        op = args[0].flatten
        run_options.send("#{op[0]}=", op[1])
      else
        run_options
      end
    end

    # Capture some other opts
    ALLOWED_CONFIG_OPTIONS.each do |op|
      self.send(:define_method, op) do |value|
        opt.send("#{op}=".to_sym, value)
      end
    end

    # Shortcut to create new registrar's configuration
    def reg(&block)
      Signal.add_trap(0) { reg.safe_release! }
      reg = Registrar.new
      reg.logger = opt.logger if opt.logger
      reg.config.instance_eval(&block)
      registrars[reg.config.device] = reg
    end

    # Calculate current registrars list
    def calc_reg_list(device = :all)
      registrars.find_all { |dev, reg| device.to_sym == :all || device.to_s == dev }.map { |vp| vp[1] }
    end

    # Initiate new dante runner
    def init_dante_runner
      dante_opts = {:pid_path => '/tmp/videoreg.pid', :log_path => opt.log_path}
      dante_opts.merge!(:kill => true) if opt.action == :kill
      dante_opts.merge!(:pid_path => opt.pid_path) if opt.pid_path
      Dante::Runner.new(DAEMON_NAME, dante_opts)
    end

    # Run daemon
    def run_daemon(regs)
      Signal.add_trap("TERM") { File.unlink(opt.pid_path) if File.exists?(opt.pid_path) }
      # Run message thread
      mq_listen do |connection, message|
        begin
          message = JSON.parse(message)
          raise "Unexpected message struct received: #{message}!" unless message.is_a?(Hash)
          opt.device = message["arg"] if message["arg"]
          case (message["msg"])
            when MSG_HALT then
              logger.info "HALT MESSAGE RECEIVED!"
              calc_reg_list(opt.device).each { |reg| reg.halt! }
            when MSG_RECOVER then
              logger.info "RECOVER MESSAGE RECEIVED!"
              calc_reg_list(opt.device).each { |reg| reg.recover! }
            else
              logger.info "UNKNOWN MESSAGE RECEIVED!"
          end
        rescue => e
          logger.error "Exception during incoming message processing: #{e.message}: \n#{e.backtrace.join("\n")}"
        end
      end
      # Run main thread
      regs.map { |reg|
        logger.info "Starting continuous registration from device #{reg.device}..."
        reg.continuous
      }.each { |t|
        while true do
          t.join(MAX_THREAD_WAIT_LIMIT_SEC)
        end
      }
    end

    # Shortcut to run action on registrar(s)
    def run(device = :all, action = opt.action)

      # Input
      @registrars = calc_reg_list(device)
      @dante_runner = init_dante_runner
      opt.action, action = :run, :run if @dante_runner.daemon_stopped? && opt.action == :recover

      # Main actions switch
      puts "Running command '#{opt.action}' for device(s): '#{device}'..."
      case action
        when :kill then
          @dante_runner.stop
        when :recover then
          mq_send(MSG_RECOVER, device)
        when :ensure then
          [{:daemon_running? => @dante_runner.daemon_running?}] + @registrars.map { |reg|
            {:device => reg.device, :device_exists? => reg.device_exists?, :process_alive? => reg.process_alive?}
          }
        when :halt then
          mq_send(MSG_HALT, device)
        when :run then
          @dante_runner.execute(:daemonize => true) {
            logger.info "Starting daemon with options: #{opt.marshal_dump}"
            run_daemon(@registrars)
          }
        when :reset then
          @registrars.each { |reg|
            reg.force_release_lock!
          }
        else
          raise "Unsupported action #{action} provided to runner!"
      end
    end

  end


end

####################################################
# Extend ruby signal to support several listeners
def Signal.add_trap(sig, &block)
  @added_signals = {} unless @added_signals
  @added_signals[sig] = [] unless @added_signals[sig]
  @added_signals[sig] << block
end

# catch interrupt signal && call all listeners
Signal.trap("TERM", proc { @added_signals && @added_signals[0].each { |p| p.call } })



