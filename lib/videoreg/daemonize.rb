require_relative 'base'
require 'dante'

module Videoreg
  class Daemonize < Videoreg::Base
    def self.run(pname, pidfile, &block)
      Dante::Runner.new(pname).execute(:daemonize => true, :pid_path => pidfile) do
        yield
      end
    end
  end
end