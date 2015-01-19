# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'crossdoc/version'

Gem::Specification.new do |spec|
  spec.name          = 'crossdoc'
  spec.version       = Crossdoc::VERSION
  spec.authors       = ['Andy Selvig']
  spec.email         = ['ajselvig@gmail.com']
  spec.summary       = 'Ruby server library and JavaScript client library for generating PDFs from the CrossDoc format'
  spec.description   = 'CrossDoc is a platform-independent document interchange program. '
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_dependency 'prawn'
  spec.add_dependency 'prawn-svg'
  spec.add_dependency 'activesupport'
end
