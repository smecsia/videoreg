Gem::Specification.new do |s|
  s.name = 'videoreg'
  s.version = '0.1'
  s.date = '2012-06-22'
  s.summary = 'VideoReg'
  s.description = 'Video Registration scripts'
  s.authors = ["Ilya Sadykov"]
  s.email = 'i.sadykov@i-free.com'
  s.add_development_dependency 'rspec', '~> 2.10.0'
  s.add_runtime_dependency 'daemons', '~> 1.1.8'
  s.executables = ['videoreg']
  s.files = %w(lib/videoreg.rb)
end