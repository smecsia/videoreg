require 'pathname'

require Pathname.new(File.dirname(File.expand_path(__FILE__))).join('lib/videoreg.rb')

Gem::Specification.new do |s|
  s.name = 'videoreg'
  s.version = Videoreg::VERSION
  s.date = '2012-06-22'
  s.authors = ["Ilya Sadykov"]
  s.email = 'i.sadykov@i-free.com'
  s.homepage = ""
  s.summary = %q{Video registration script}
  s.description = %q{Video Registration scripts. Allows to register continuously}

  s.add_development_dependency 'rspec', '~> 2.10.0'
  s.add_runtime_dependency 'dante'
  s.add_runtime_dependency 'open4'
  s.add_runtime_dependency 'god'

  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = %w(lib)
end