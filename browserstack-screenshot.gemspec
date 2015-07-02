# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'screenshot/version'

Gem::Specification.new do |gem|
  gem.name          = 'browserstack-screenshot'
  gem.version       = Screenshot::VERSION
  gem.authors       = %w(ahmed1490 utsavkesharwani)
  gem.email         = ['ahmed1490@gmail.com', 'utsav.kesharwani@gmail.com']
  gem.description   = 'Ruby wrapper for Browserstack screenshots API'
  gem.summary       = 'Get screenshots from live browsers using this gem'
  gem.homepage      = 'https://github.com/browserstack/ruby-screenshots'
  gem.license       = ''

  gem.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  gem.executables   = gem.files.grep(%r{^bin/}) { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.add_development_dependency 'rake'
  gem.add_runtime_dependency('yajl-ruby')
end
