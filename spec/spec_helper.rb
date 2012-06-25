require 'rspec'
require_relative '../lib/videoreg'
Dir["#{File.dirname(__FILE__)}/../lib/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  config.color_enabled = true
  config.formatter     = 'documentation'
end