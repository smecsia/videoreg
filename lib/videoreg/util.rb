module Videoreg
  class Util

    class << self
      def which(cmd)
        exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
        ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
          exts.each { |ext|
            exe = "#{path}/#{cmd}#{ext}"
            return exe if File.executable? exe
          }
        end
        nil
      end

      def proc_alive?(pid)
        return false unless pid
        begin
          Process.kill(0, pid)
          true
        rescue Errno::ESRCH
          false
        end
      end

      # Extracts the connection string for the rabbitmq service from the
      # service information provided by Cloud Foundry in an environment
      # variable.
      def amqp_url
        services = JSON.parse(ENV['VCAP_SERVICES'], :symbolize_names => true)
        url = services.values.map do |srvs|
          srvs.map do |srv|
            if srv[:label] =~ /^rabbitmq-/
              srv[:credentials][:url]
            else
              []
            end
          end
        end.flatten!.first
      end

    end

  end
end