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
task :videoreg, :device, :duration, :storage do |t, args|
  Videoreg::Registrar.new do |c|
    c.device = args[:device]
    c.duration = args[:duration]
    c.storage = args[:storage]
  end.continuous
end

