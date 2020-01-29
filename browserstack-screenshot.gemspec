# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'screenshot/version'

Gem::Specification.new do |spec|
  spec.name          = "browserstack-screenshot"
  spec.version       = Screenshot::VERSION
  spec.authors       = ["ahmed1490", "utsavkesharwani"]
  spec.email         = ["ahmed1490@gmail.com", "utsav.kesharwani@gmail.com"]
  spec.description   = %q{Ruby wrapper for Browserstack screenshots API}
  spec.summary       = %q{Get screenshots from live browsers using this gem}
  spec.homepage      = "https://github.com/browserstack/ruby-screenshots"
  spec.license       = ""

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rake"
  spec.add_dependency("yajl-ruby", "1.3.1")
end
