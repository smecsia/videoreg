Dir[File.dirname(__FILE__)+"/videoreg/*.rb"].each { |f| require f }
require 'rubygems'
require 'logger'

####################################################
# Main videoreg module
module Videoreg

  @@registered_regs = {}
  @@perform_action = :run

  def self.perform_action=(value)
    @@perform_action = value
  end

  def self.perform_action
    @@perform_action
  end

  def self.registrars
    @@registered_regs
  end

  def self.capture_all(*devices, &block)
    threads = devices.map do |device|
      Thread.new {
        Videoreg::Registrar.new do |conf|
          conf.device = device
          conf.instance_eval(&block)
        end.continuous
      }
    end
    threads.each { |t| t.join }
  end

  def self.release_locks!(*locks)
    locks.each { |lock| File.unlink(lock) if File.exists?(lock) }
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
exit_proc = proc { @added_signals && @added_signals[0].each { |p| p.call } }
Signal.trap("TERM", exit_proc)
Signal.trap(0, exit_proc)


####################################################
# Shortcut to create new registrar's thread
def reg(&block)
  reg = Videoreg::Registrar.new
  reg.config.instance_eval(&block)
  Videoreg.registrars[reg.config.device] = reg
  Signal.add_trap(0) { reg.safe_release }
end

# Shortcut to run all registrars continuous
def run(device = :all)
  Videoreg::Base.logger.info("Starting command '#{Videoreg.perform_action}' for device: '#{device}'...")
  registrars = Videoreg.registrars.find_all { |dev, reg| device.to_sym == :all || device == dev }.map { |vp| vp[1] }
  case Videoreg.perform_action
    when :run then
      registrars.map { |reg|
        Videoreg::Base.logger.info("Starting continuous registration with device #{reg.device}...")
        Thread.new { reg.continuous }
      }.each { |t| t.join }
    when :clear then
      registrars.each { |reg|
        Videoreg::Base.logger.info("Removing lockfile #{reg.config.lockfile}...")
        Videoreg.release_locks!(reg.config.lockfile)
      }
  end
end
