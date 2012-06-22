module Videoreg
  class Config

    attr_accessor :device
    attr_accessor :resolution
    attr_accessor :fps
    attr_accessor :duration
    attr_accessor :command
    attr_accessor :filename

    def initialize
      @device = "/dev/video1"
      @resolution = "320x240"
      @fps = 15
      @duration = 10
      @filename = '#{time}-video1.avi'
      @command =  'ffmpeg -r "#{fps}" -s "#{resolution}" -f video4linux2 -r ntsc -i "#{device}"  -vcodec  mjpeg  -t  #{duration} -an -y #{outfile}'
    end

    def time
      "#{DateTime.now.strftime("%Y%m%d-%H%M%S%L")}"
    end

    def outfile
      tpl(filename)
    end

    def cmd
      tpl(command)
    end

    def tpl(str)
      eval("\"#{str}\"")
    end
  end
end