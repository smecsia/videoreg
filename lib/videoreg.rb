require_relative 'videoreg/base'
require_relative 'videoreg/lockfile'
require_relative 'videoreg/config'
require 'rubygems'
require 'logger'

module Videoreg

  class Registrar < Videoreg::Base

    DELEGATE_TO_CONFIG = [:cmd, :outfile, :resolution, :fps, :duration, :device, :storage]
    attr_reader :config

    public # Public methods:

    def initialize
      @config = Videoreg::Config.new
    end

    def self.capture_all(*devices, &block)
      threads = devices.map do |device|
        Thread.new {
          Videoreg::Registrar.capture_continuously do |conf|
            block.call(device, conf)
          end
        }
      end
      threads.each { |t| t.join }
    end

    def self.release_locks(*locks)
      locks.each { |lock| File.unlink(lock) if File.exists?(lock) }
    end

    def self.capture_continuously(&block)
      logger.info "Starting the continuous capture..."
      while true do
        reg = self.new
        reg.configure(&block)
        unless reg.device_exists?
          logger.error "Capture failed! Device #{reg.device} does not exist!"
          return
        end
        begin
          runner = reg.run
          logger.info "Waiting for registrar (#{reg.device}) to finish the part (#{reg.outfile})..."
          runner.join
        rescue RuntimeError => e
          logger.error(e.message)
          return nil
        ensure
          reg.stop
        end
        logger.info "Registrar (#{reg.device}) has finished to capture the part (#{reg.outfile})..."
      end
    end

    def configure
      @thread = nil
      yield @config
    end

    def method_missing(m)
      DELEGATE_TO_CONFIG.include?(m.to_sym) ? config.send(m) : super
    end

    def run
      logger.info "Spawning a new thread and process to capture video from device '#{device}'..."
      raise "Lockfile already exists '#{config.lockfile}'..." if File.exist?(config.lockfile)
      Thread.new do
        logger.info "Running the command: '#{cmd}'..."
        base_cmd = cmd.split(" ").first
        raise "#{base_cmd} not found on your system. Please install it or add it to your PATH" if which(base_cmd).nil? && !File.exists?(base_cmd)
        IO.popen(cmd, "r") do |io|
          raise "Cannot lock the lock-file '#{config.lockfile}'..." unless lock(io.pid)
          io.read
        end
        release
      end
    end

    def device_exists?
      File.exists?(device)
    end

    def stop
      @thread && @thread.kill
      release
    end

    def alive?
      lockfile.verify
    end

    private # Private methods:

    def lockfile
      @lockfile ||= Lockfile.new(config.lockfile)
    end

    def lock(pid)
      lockfile.lock(pid)
    end

    def release
      lockfile.release
    end

  end
end
