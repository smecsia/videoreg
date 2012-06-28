Dir[File.dirname(__FILE__)+"/videoreg/*.rb"].each { |f| require f }
require 'rubygems'
require 'logger'
require 'ostruct'
require 'amqp'
require_relative './videoreg/util'

####################################################
# Main videoreg module
module Videoreg

  VERSION = "0.1"
  DAEMON_NAME = "videoreg"
  MAX_THREAD_WAIT_LIMIT_SEC = 360

  MSG_HALT = "HALT"
  MSG_RECOVER = "RECOVER"
  MSG_RUN = "RUN"

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
    def mq_connect(opts, &block)
      Videoreg::Base.logger.info "Connecting to RabbitMQ #{opts.mq_host} / #{opts.mq_queue}"
      AMQP.connect(:host => opts.mq_host) do |connection|
        Videoreg::Base.logger.info "Creating MQ channel..."
        channel = AMQP::Channel.new(connection)
        block.call(connection, channel)
      end
    end

    def mq_disconnect(connection)
      Videoreg::Base.logger.info "Disconnecting from RabbitMQ..."
      connection.close { EM.stop { exit } }
    end

    def mq_listen(&block)
      Thread.new {
        EventMachine.run do
          mq_connect(opt) do |connection, channel|
            Videoreg::Base.logger.info "Subscribing to the new queue '#{opt.mq_queue}'..."
            channel.queue(opt.mq_queue, :auto_delete => true).subscribe do |msg|
              Videoreg::Base.logger.info "Received message from RabbitMQ #{msg}..."
              block.call(connection, msg) if block_given?
            end
            Signal.add_trap(0) { mq_disconnect(connection) }
          end
        end
      }
    end

    def mq_send(message, arg = nil)
      EventMachine.run do
        mq_connect(opt) do |connection, channel|
          Videoreg::Base.logger.info "Publish message to RabbitMQ '#{message}' with arg '#{arg}' to '#{opt.mq_queue}'..."
          channel.direct("").publish({:msg => message, :arg => arg}, :routing_key => opt.mq_queue)
          mq_disconnect(connection)
        end
      end
    end

    def mq_exchange
      @mq_exchange
    end

    def run_options
      @run_options
    end

    def registrars
      @registered_regs
    end

  end


end

####################################################
# Extend ruby signal's to support several listeners
def Signal.add_trap(sig, &block)
  @added_signals = {} unless @added_signals
  @added_signals[sig] = [] unless @added_signals[sig]
  @added_signals[sig] << block
end

# catch interrupt signal && call all listeners
Signal.trap("TERM", proc { @added_signals && @added_signals[0].each { |p| p.call } })


####################################################
# Options
def opt(*args)
  if !args.empty? && args[0].is_a?(Hash)
    op = args[0].flatten
    Videoreg.run_options.send("#{op[0]}=", op[1])
  else
    Videoreg.run_options
  end
end

# Shortcut to create new registrar's configuration
def reg(&block)
  Signal.add_trap(0) { reg.safe_release! }
  reg = Videoreg::Registrar.new
  reg.logger = opt.logger if opt.logger
  reg.config.instance_eval(&block)
  Videoreg.registrars[reg.config.device] = reg
end

# Calculate current registrars list
def calc_reg_list(device = :all)
  Videoreg.registrars.find_all { |dev, reg| device.to_sym == :all || device.to_s == dev }.map { |vp| vp[1] }
end

# Initiate new dante runner
def init_dante_runner
  dante_opts = {:pid_path => '/tmp/videoreg.pid', :log_path => opt.log_path}
  dante_opts.merge!(:kill => true) if opt.action == :kill
  dante_opts.merge!(:pid_path => opt.pid_path) if opt.pid_path
  Dante::Runner.new(Videoreg::DAEMON_NAME, dante_opts)
end

# Run daemon
def run_daemon(registrars)
  # Run message thread
  Videoreg.mq_listen do |connection, message|
    case (message)
      when Videoreg::MSG_HALT then
        Videoreg::Base.logger.info "HALT MESSAGE RECEIVED!"
      when Videoreg::MSG_RECOVER then
        Videoreg::Base.logger.info "RECOVER MESSAGE RECEIVED!"
    end
  end
  # Run main thread
  registrars.map { |reg|
    puts "Starting continuous registration from device #{reg.device}..."
    reg.continuous
  }.each { |t| t.join(Videoreg::MAX_THREAD_WAIT_LIMIT_SEC) }
end

# Shortcut to run action on registrar(s)
def run(device = :all, action = opt.action)

  # Input
  @registrars = calc_reg_list(device)
  @dante_runner = init_dante_runner
  opt.action = :run if @dante_runner.daemon_stopped? && opt.action == :recover

  # Main actions switch
  puts "Running command '#{opt.action}' for device(s): '#{device}'..."
  case action
    when :kill then
      @dante_runner.stop
    when :recover then
      Videoreg.mq_send(Videoreg::MSG_RECOVER, device)
    when :ensure then
      return @registrars.map { |reg|
        {:device => reg.device, :device_exists? => reg.device_exists?, :process_alive? => reg.process_alive?}
      }
    when :halt then
      Videoreg.mq_send(Videoreg::MSG_HALT, device)
    when :run then
      @dante_runner.execute(:daemonize => true) {
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


