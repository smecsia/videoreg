require 'rspec/core/rake_task'
require_relative 'lib/videoreg'

task :default => :help

desc "Build gem"
task :install do
  %x[gem build videoreg.gemspec]
  %x[sudo gem install #{Dir["*.gem"].sort.last}]
end

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


def lck_file(device)
  "/tmp/videoreg.#{device}.lock"
end

desc "Capture the video from three different devices"
task :capture_three do
  Videoreg::Registrar.capture_all(
      'device0',
      'device1',
      'device2') do |device, conf|
    conf.device = '/dev/' + device
    conf.filename = '#{time}-'+device+'.avi'
    conf.storage = '/tmp/' + device
    conf.lockfile = lck_file(device)
  end
end

desc "Reset lockfiles"
task :capture_reset do
  Videoreg::Registrar.release_locks(
      lck_file('device0'),
      lck_file('device1'),
      lck_file('device2')
  )
end