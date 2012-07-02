Dir[File.dirname(File.expand_path(__FILE__))+"/videoreg/*.rb"].each { |f| require f }
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
  MAX_THREAD_WAIT_LIMIT_SEC = 600

  ALLOWED_CONFIG_OPTIONS = %w[mq_host mq_queue pid_path log_path device]

  MSG_HALT = 'HALT'
  MSG_RECOVER = 'RECOVER'
  MSG_PAUSE = 'PAUSE'
  MSG_RESUME = 'RESUME'
  MSG2ACTION = {MSG_HALT => :halt!, MSG_PAUSE => :pause!, MSG_RESUME => :resume!, MSG_RECOVER => :recover!}

  @registered_regs = {}
  @time_started = Time.now
  @run_options = OpenStruct.new(
      :device => :all,
      :action => :run,
      :log_path => 'videoreg.log',
      :pid_path => '/tmp/videoreg.pid',
      :mq_host => '127.0.0.1',
      :mq_queue => 'ifree.videoreg.server'
  )

  class << self
    # Version info
    def version_info
      "#{DAEMON_NAME} v.#{VERSION}"
    end

    # Disconnect from RabbitMQ
    def mq_disconnect(connection)
      logger.info "Disconnecting from RabbitMQ..."
      connection.close { EM.stop { exit } }
    end

    # Listen the incoming messages from RabbitMQ
    def mq_listen(&block)
      Thread.new {
        begin
          logger.info "New messaging thread created for RabbitMQ #{opt.mq_host} / #{opt.mq_queue}"
          AMQP.start(:host => opt.mq_host) do |connection|
            q = AMQP::Channel.new(connection).queue(opt.mq_queue)
            q.subscribe do |msg|
              Videoreg::Base.logger.info "Received message from RabbitMQ #{msg}..."
              block.call(connection, msg) if block_given?
            end
            Signal.add_trap("TERM") { q.delete; mq_disconnect(connection) }
            Signal.add_trap(0) { q.delete; mq_disconnect(connection) }
          end
        rescue => e
          logger.error "Error during establishing the connection to RabbitMQ: #{e.message}"
          @dante_runner.stop if @dante_runner
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
      r = Registrar.new
      Signal.add_trap(0) { r.safe_release! }
      r.logger = opt.logger if opt.logger
      r.config.instance_eval(&block)
      registrars[r.config.device] = r
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
      @time_started = Time.now
      # Run message thread
      mq_listen do |connection, message|
        begin
          raise "Unexpected message struct received: #{message}!" unless (message = JSON.parse(message)).is_a?(Hash)
          opt.device = message["arg"] if message["arg"]
          if (action = MSG2ACTION[message["msg"]])
            logger.info "#{message["msg"]} MESSAGE RECEIVED!"
            calc_reg_list(opt.device).each { |reg| reg.send(action) }
          else
            logger.error "UNKNOWN MESSAGE RECEIVED!"
          end
        rescue => e
          logger.error "Exception during incoming message processing: #{e.message}: \n#{e.backtrace.join("\n")}"
        end
      end
      # Run main thread
      regs.map { |reg|
        logger.info "Starting continuous registration from device #{reg.device}..."
        {:reg => reg, :thread => reg.continuous}
      }.each { |reg_hash|
        while true do # avoid deadlock exception
          reg_hash[:thread].join(MAX_THREAD_WAIT_LIMIT_SEC)
          break if reg_hash[:reg].terminated? # break if thread was terminated
        end if reg_hash[:reg] && reg_hash[:thread]
      }
      @time_ended = Time.now
      logger.info "Daemon finished execution. Uptime #{@time_ended - @time_started} sec"
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
        when :pause then
          mq_send(MSG_PAUSE, device) if @dante_runner.daemon_running?
        when :resume then
          mq_send(MSG_RESUME, device) if @dante_runner.daemon_running?
        when :recover then
          mq_send(MSG_RECOVER, device) if @dante_runner.daemon_running?
        when :ensure then
          uptime = (@dante_runner.daemon_running?) ? Time.now - File.stat(opt.pid_path).ctime : 0
          [{:daemon_running? => @dante_runner.daemon_running?, :uptime => uptime}] + @registrars.map { |reg|
            {
                :device => reg.device,
                :device_exists? => reg.device_exists?,
                :process_alive? => reg.process_alive?,
                :paused? => reg.paused?
            }
          }
        when :halt then
          mq_send(MSG_HALT, device) if @dante_runner.daemon_running?
        when :run then
          @dante_runner.execute(:daemonize => true) {
            logger.info "Starting daemon with options: #{opt.marshal_dump}"
            run_daemon(@registrars)
          }
        when :reset then
          @registrars.each { |reg|
            reg.force_release_lock!
          }
          logger.info "Forced to release pidfile #{opt.pid_path}"
          File.unlink(opt.pid_path) if File.exists?(opt.pid_path)
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



