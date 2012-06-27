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
  case Videoreg.perform_action
    when :run then
      Videoreg.registrars.find_all { |dev, reg| device == :all || device == dev }.map { |reg_pair|
        Thread.new { reg_pair[1].continuous }
      }.each { |t| t.join }
    when :clear then
      Videoreg.registrars.each { |dev, reg|
        Videoreg.release_locks!(reg.config.lockfile)
      }
  end
end
