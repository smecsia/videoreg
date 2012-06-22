require_relative 'videoreg/config'

module Videoreg
  class Registrar

    CONFIG_METHODS = [:cmd, :outfile, :resolution, :fps, :duration, :device]
    attr_reader :config

    def configure
      @config = Videoreg::Config.new
      yield @config
    end

    def method_missing(m)
      CONFIG_METHODS.include?(m.to_sym) ? config.send(m) : super
    end
  end

end
