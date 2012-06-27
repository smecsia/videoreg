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
    end

    def time
      "#{Time.new.strftime("%Y%m%d-%H%M%S%L")}"
    end

    def outfile
      "#{storage}/#{filename}"
    end

    def method_missing(*args)
      if args.length == 1
        tpl(eval("@#{args[0]}"))
      elsif args.length == 2
        eval("@#{args[0]}='#{args[1]}'")
      else
        super
      end
    end

    def devname
      device.split('/').last
    end
  end
end