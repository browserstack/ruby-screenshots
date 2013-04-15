# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'screenshots/version'

Gem::Specification.new do |spec|
  spec.name          = "browserstack-screenshots"
  spec.version       = Browserstack::Screenshots::VERSION
  spec.authors       = ["ahmed1490"]
  spec.email         = ["ahmed1490@gmail.com"]
  spec.description   = %q{Ruby API wrapper for Browserstack screenshots}
  spec.summary       = %q{Get screenshots from live browsers using this gem}
  spec.homepage      = "http:www.browserstack.com/screenshots"
  spec.license       = ""

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rake"
  spec.add_dependency("yajl-ruby", "1.1.0")
end
