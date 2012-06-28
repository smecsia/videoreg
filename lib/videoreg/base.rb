require 'logger'
require 'stringio'
require_relative 'util'
module Videoreg
  class Base
    @@logger = ::Logger.new(STDOUT)

    def logger
      self.class.logger
    end

    def logger=(log)
      self.class.logger=log
    end

    def self.logger=(log)
      @@logger = log
    end

    def self.logger
      @@logger
    end

    # Applies current context to the templated string
    def tpl(str)
      eval("\"#{str}\"")
    end

    # Check if process is alive
    def proc_alive?(pid)
      Videoreg::Util.proc_alive?(pid)
    end

    # Cross-platform way of finding an executable in the $PATH.
    #
    #   which('ruby') #=> /usr/bin/ruby
    def which(cmd)
      Videoreg::Util.which(cmd)
    end
  end
end