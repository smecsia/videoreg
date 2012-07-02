require 'open4'
require 'pathname'

require_relative "base"

module Videoreg
  class Registrar < Videoreg::Base
    DELEGATE_TO_CONFIG = [:command, :outfile, :resolution, :fps, :duration, :device, :storage, :base_cmd, :store_max]
    attr_reader :config

    #################################
    public # Public methods:

    def initialize(&block)
      @config = Videoreg::Config.new
      @pid = nil
      @halted_mutex = nil
      @terminated = false
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
      @terminated = false
      @thread = Thread.new do
        while true do
          unless @halted_mutex.nil?
            logger.info "Registrar (#{device}) HALTED. Waiting for the restore message..."
            @halted_mutex.lock
          end
          unless device_exists?
            logger.error "Capture failed! Device #{device} does not exist!"
            terminate!
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
            terminate!
          end
        end
      end
    end

    def run
      logger.info "Spawning a new process to capture video from device '#{device}'..."
      raise "Lockfile already exists '#{config.lockfile}'..." if File.exist?(config.lockfile)
      logger.info "Running the command: '#{command}'..."
      raise "#{base_cmd} not found on your system. Please install it or add it to your PATH" if which(base_cmd).nil?&& !File.exists?(base_cmd)
      Open4::popen4(command) do |pid, stdin, stdout, stderr|
        @pid = pid
        raise "Cannot lock the lock-file '#{config.lockfile}'..." unless lock(pid)
        output = stdout.read + stderr.read
        raise "FATAL ERROR: Cannot capture video: \n #{output}" if error?(output)
      end
    ensure
      release
    end

    def pid
      @pid || ((rpid = lockfile.lockcode) ? rpid.to_i : nil)
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

    def halt!
      logger.info "Registrar #{device} HALTED! Killing process..."
      @halted_mutex = Mutex.new
      @halted_mutex.lock
      kill_process!
    end

    def pause!
      logger.info "Registrar #{device} pausing process with pid #{pid}..."
      Process.kill("STOP", pid) if process_alive?
    end

    def recover!
      logger.info "Registrar #{device} UNHALTED! Recovering process..."
      @halted_mutex.unlock if @halted_mutex && @halted_mutex.locked?
      @halted_mutex = nil
    end

    def resume!
      logger.info "Registrar #{device} resuming process with pid #{pid}..."
      Process.kill("CONT", pid) if process_alive?
    end

    # Kill just the underlying process
    def kill_process!
      begin
        logger.info("Killing the process for #{device} : #{pid}")
        Process.kill("KILL", pid) if process_alive?
        Process.getpgid
      rescue => e
        logger.warn("An attempt to kill already killed process (#{pid}): #{e.message}")
      end
    end

    # Kill completely
    def kill!
      terminate!
      kill_process! if process_alive?
    ensure
      safe_release!
    end

    # Terminate the main thread
    def terminate!
      @terminated = true
      @thread.kill if @thread
    ensure
      safe_release!
    end

    def safe_release!
      release if File.exists?(config.lockfile)
    end

    def force_release_lock!
      logger.info("Forced to release lockfile #{config.lockfile}...")
      File.unlink(config.lockfile) if File.exists?(config.lockfile)
    end

    def device_exists?
      File.exists?(device)
    end

    def self_alive?
      process_alive? && lockfile.readlock
    end

    def process_alive?
      !pid.to_s.empty? && pid.to_i != 0 && proc_alive?(pid)
    end

    def terminated?
      @terminated
    end

    def paused?
      process_alive? && (`ps -p #{pid} -o stat=`.chomp == "T")
    end

    #################################
    private # Private methods:

    def error?(output)
      if output =~ /No such file or directory/
        output.split("\n").last
      elsif output =~ /Input\/output error/
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