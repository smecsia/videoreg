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


      def humanize(secs)
        [[60, :sec], [60, :min], [24, :hr], [1000, :days]].map { |count, name|
          if secs > 0
            secs, n = secs.divmod(count)
            "#{n.to_i}#{name}"
          end
        }.compact.reverse.join(' ')
      end


      def udevinfo(maxcount)
        res = []
        maxcount.times do |dnum|
          devpath_parts = nil
          Open4::popen4("udevadm info --query all --name video#{dnum} | grep DEVPATH") do |pid, stdin, stdout, stderr|
            devpath = stdout.read.match(/DEVPATH=(.*)\n$/)
            unless devpath.nil?
              devpath_parts = devpath[1].match(/(\/.*\/)(usb\d+)\/(\d*-\d*)((?:\/.*)?\/video4linux\/)(video\d+)/)
            end
          end
          unless devpath_parts.nil?
            res << {
                :prefix => devpath_parts[1],
                :usbhub => devpath_parts[2],
                :usbport => devpath_parts[3],
                :postfix => devpath_parts[4],
                :device => "/dev/#{devpath_parts[5]}"
            }
          end
        end
        res
      end

    end

  end
end