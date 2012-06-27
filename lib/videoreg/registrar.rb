require 'open4'
require 'pathname'

module Videoreg
  class Registrar < Videoreg::Base
    DELEGATE_TO_CONFIG = [:command, :outfile, :resolution, :fps, :duration, :device, :storage]
    attr_reader :config

    public # Public methods:

    def initialize(&block)
      @config = Videoreg::Config.new
      configure(&block) if block_given?
    end

    def configure
      @thread = nil
      yield @config
    end

    def method_missing(m)
      DELEGATE_TO_CONFIG.include?(m.to_sym) ? config.send(m) : super
    end

    def continuous
      logger.info "Starting the continuous capture..."
      while true do
        unless device_exists?
          logger.error "Capture failed! Device #{device} does not exist!"
          return
        end
        begin
          logger.info "Cleaning old files from storage (#{storage})... (MAX: #{config.store_max})"
          clean_old_files!
          logger.info "Waiting for registrar (#{device}) to finish the part (#{outfile})..."
          run # perform one registration
          logger.info "Registrar (#{device}) has finished to capture the part (#{outfile})..."
        rescue RuntimeError => e
          logger.error(e.message)
          logger.info "Registrar (#{device}) has failed to capture the part (#{outfile})..."
          return nil
        ensure
          stop
        end
      end
    end

    def run
      logger.info "Spawning a new thread and process to capture video from device '#{device}'..."
      raise "Lockfile already exists '#{config.lockfile}'..." if File.exist?(config.lockfile)
      logger.info "Running the command: '#{command}'..."
      base_cmd = command.split(" ").first
      raise "#{base_cmd} not found on your system. Please install it or add it to your PATH" if which(base_cmd).nil? && !File.exists?(base_cmd)
      Open4::popen4(command) do |pid, stdin, stdout, stderr|
        raise "Cannot lock the lock-file '#{config.lockfile}'..." unless lock(pid)
        output = stdout.read + stderr.read
        raise "FATAL ERROR: Cannot capture video: \n #{output}" if error?(output)
      end
      release
    end

    def clean_old_files!
      all_saved_files = Dir[Pathname.new(storage).join("*#{File.extname(config.filename)}").to_s].sort_by { |c|
        File.stat(c).ctime
      }.reverse
      if all_saved_files.length > config.store_max.to_i
        all_saved_files[config.store_max.to_i..-1].each do |saved_file|
          logger.info "Removing saved file #{saved_file}..."
          File.unlink(saved_file) if File.exists?(saved_file)
        end
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

    def safe_release
      release if alive?
    end

    private # Private methods:

    def error?(output)
      if output =~ /No such file or directory/
        output.split("\n").last
      else
        nil
      end
    end

    def lockfile
      @lockfile ||= Lockfile.new(config.lockfile)
    end

    def lock(pid)
      logger.info "Locking registrar's #{config.device} (PID: #{pid}) lock file #{config.lockfile}..."
      lockfile.lock(pid)
    end

    def release
      logger.info "Releasing registrar's #{config.device} lock file #{config.lockfile}..."
      lockfile.release
    end

  end
end