# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'crossdoc/version'

Gem::Specification.new do |spec|
  spec.name          = 'crossdoc'
  spec.version       = CrossDoc::VERSION
  spec.authors       = ['Andy Selvig']
  spec.email         = ['ajselvig@gmail.com']
  spec.summary       = 'Ruby server library and JavaScript client library for generating PDFs from the CrossDoc format'
  spec.description   = 'CrossDoc is a platform-independent document interchange program. '
  spec.homepage      = 'https://github.com/TinyMission/crossdoc'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency 'bundler', '~> 2.3'
  spec.add_development_dependency 'rake'
  spec.add_dependency 'matrix'
  spec.add_dependency 'prawn', '~> 2.4.0'
  spec.add_dependency 'prawn-svg'
  spec.add_dependency 'ttfunk', '~> 1.7.0'
  spec.add_dependency 'activesupport', '>= 4.2.0'
  spec.add_dependency 'railties'
  spec.add_dependency 'kramdown'
  spec.add_dependency 'mini_magick'

  spec.required_ruby_version = '>= 3.0.0'
end
