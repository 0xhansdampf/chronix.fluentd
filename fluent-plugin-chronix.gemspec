lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |s|
  s.name = 'fluent-plugin-chronix'
  s.version         = "0.1.2"
  s.licenses = ["Apache License (2.0)"]
  s.summary = "This output stores your logs in chronix"
  s.description = "This gem is a fluentd plugin required to be installed on top of fluentd"
  s.authors = ["Max Jalowski"]
  s.email = "max.jalowski@fau.de"

  # Files
  s.files = Dir['lib/**/*','spec/**/*','vendor/**/*','*.gemspec','*.md','Gemfile','LICENSE']
   # Tests
  s.test_files = s.files.grep(%r{^(test|spec|features)/})
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.require_paths = ["lib"]

  # Gem dependencies
  s.add_runtime_dependency "fluentd", ">= 0.12.1"
  s.add_runtime_dependency "msgpack"
  s.add_runtime_dependency "rsolr"
  s.add_runtime_dependency "protobuf"

  s.add_development_dependency "bundler"
  s.add_development_dependency "minitest"
  s.add_development_dependency "rake"
  s.add_development_dependency "rspec"
  s.add_development_dependency "test-unit"
  s.add_development_dependency "test-unit-rr"
end
