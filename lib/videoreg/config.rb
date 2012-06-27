require_relative 'base'
module Videoreg
  class Config < Base

    def initialize
      @device = '/dev/video1'
      @resolution = '320x240'
      @fps = 25
      @duration = 10
      @filename = '#{time}-#{devname}.DEFAULT.avi'
      @command = 'ffmpeg -r #{fps} -s #{resolution} -f video4linux2 -r ntsc -i #{device} -vcodec  mjpeg -t #{duration} -an -y #{outfile}'
      @storage = '/tmp/#{devname}'
      @lockfile = '/tmp/videoreg.#{devname}.DEFAULT.lck'
      @store_max = 50
    end

    def time
      "#{Time.new.strftime("%Y%m%d-%H%M%S%L")}"
    end

    def logger
      @logger || self.class.logger
    end

    def store_max(*args)
      (args.length > 0) ? (self.store_max=(args.shift)) : (@store_max.to_i)
    end

    def outfile
      "#{storage}/#{filename}"
    end

    # set or get inner variable value
    # depending on arguments count
    def method_missing(*args)
      if args.length == 2 || args[0] =~ /=$/
        mname = args[0].to_s.gsub(/=/, '')
        value = args.last
        eval("@#{mname}='#{value}'")
      elsif args.length == 1
        tpl(eval("@#{args[0]}"))
      else
        super
      end
    end

    def devname
      device.split('/').last
    end
  end
end