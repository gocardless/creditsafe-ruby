# coding: utf-8
# frozen_string_literal: true
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'creditsafe/version'

Gem::Specification.new do |spec|
  spec.name          = 'creditsafe'
  spec.version       = Creditsafe::VERSION
  spec.authors       = ['Pete Hamilton']
  spec.email         = ['engineering@gocardless.com']
  spec.summary       = 'Ruby client for the Creditsafe SOAP API'
  spec.description   = 'Ruby client for the Creditsafe SOAP API'
  spec.homepage      = 'https://github.com/gocardless/creditsafe-ruby'

  spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'savon', '~> 2.8'
  spec.add_runtime_dependency 'excon', '~> 0.45'

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rspec', '~> 3.1'
  spec.add_development_dependency 'rspec-its', '~> 1.2'
  spec.add_development_dependency 'guard-rspec', '~> 4.5'
  spec.add_development_dependency 'guard-rubocop', '~> 1.2'
  spec.add_development_dependency 'rubocop', '~> 0.37'
  spec.add_development_dependency 'webmock', '~> 1.20'
end
