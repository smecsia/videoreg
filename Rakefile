require 'rspec/core/rake_task'
require_relative 'lib/videoreg'

task :default => :help

desc "Run specs"
task :spec do
  RSpec::Core::RakeTask.new(:spec) do |t|
    t.pattern = './spec/**/*_spec.rb'
  end
end

desc "Show help menu"
task :help do
  puts "Available rake tasks: "
  puts "rake spec - Run specs and calculate coverage"
end


desc "Capture the video from the device"
task :capture, :device, :duration, :storage do |t, args|
  Videoreg::Registrar.capture_continuously do |c|
    c.device = args[:device]
    c.duration = args[:duration]
    c.storage = args[:storage]
  end
end


def lckfile(num)
  "/tmp/videoreg.video#{num}.lck"
end

desc "Capture the video from three different devices"
task :capture_three do |t|

  r0 = Thread.new {
    Videoreg::Registrar.capture_continuously do |c|
      c.device = '/dev/video0'
      c.filename = '#{time}-video0.avi'
      c.storage = '/tmp/video0'
      c.lockfile = lckfile(0)
    end
  }

  r1 = Thread.new {
    Videoreg::Registrar.capture_continuously do |c|
      c.device = '/dev/video1'
      c.filename = '#{time}-video1.avi'
      c.storage = '/tmp/video1'
      c.lockfile = lckfile(1)
    end
  }

  r2 = Thread.new {
    Videoreg::Registrar.capture_continuously do |c|
      c.device = '/dev/video2'
      c.filename = '#{time}-video2.avi'
      c.storage = '/tmp/video2'
      c.lockfile = lckfile(2)
    end
  }

  r0.join
  r1.join
  r2.join

end

desc "Reset lockfiles"
task :capture_reset do
  File.unlink(lckfile(0)) if File.exists?(lckfile(0))
  File.unlink(lckfile(1)) if File.exists?(lckfile(1))
  File.unlink(lckfile(2)) if File.exists?(lckfile(2))
end