require 'logger'
module Videoreg
  class Base
    @@logger = ::Logger.new(STDOUT)

    def logger
      @@logger
    end

    def self.logger
      @@logger
    end

    # Cross-platform way of finding an executable in the $PATH.
    #
    #   which('ruby') #=> /usr/bin/ruby
    def which(cmd)
      exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
      ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
        exts.each { |ext|
          exe = "#{path}/#{cmd}#{ext}"
          return exe if File.executable? exe
        }
      end
      return nil
    end
  end
end