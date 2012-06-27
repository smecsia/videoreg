require_relative 'base'
module Videoreg
  class Config < Base

    attr_accessor :device
    attr_accessor :resolution
    attr_accessor :fps
    attr_accessor :duration
    attr_accessor :command
    attr_accessor :filename
    attr_accessor :storage
    attr_accessor :lockfile

    def initialize
      @device = '/dev/video1'
      @resolution = '320x240'
      @fps = 25
      @duration = 10
      @filename = '#{time}-video1.avi'
      @command = 'ffmpeg -r #{fps} -s #{resolution} -f video4linux2 -r ntsc -i #{device} -vcodec  mjpeg -t #{duration} -an -y #{outfile}'
      @storage = '/tmp/video1'
      @lockfile = '/tmp/videoreg.video1.lck'
    end

    def time
      "#{Time.new.strftime("%Y%m%d-%H%M%S%L")}"
    end

    def outfile
      @outfile ||= "#{storage}/#{tpl(filename)}"
    end

    def cmd
      @real_command ||= tpl(command)
    end
  end
end