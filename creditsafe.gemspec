# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "creditsafe/version"

Gem::Specification.new do |spec|
  spec.name          = "creditsafe"
  spec.version       = Creditsafe::VERSION
  spec.authors       = ["GoCardless Engineering"]
  spec.email         = ["engineering@gocardless.com"]
  spec.summary       = "Ruby client for the Creditsafe SOAP API"
  spec.homepage      = "https://github.com/gocardless/creditsafe-ruby"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "activesupport"
  spec.add_runtime_dependency "excon", "~> 0.85"
  spec.add_runtime_dependency "savon", "~> 2.11"

  spec.add_development_dependency "compare-xml", "~> 0.66"
  spec.add_development_dependency "debug"
  spec.add_development_dependency "gc_ruboconfig", "~> 4.3.0"
  spec.add_development_dependency "pry", "~> 0.14"
  spec.add_development_dependency "rspec", "~> 3.8"
  spec.add_development_dependency "rspec-github", "~> 2.4.0"
  spec.add_development_dependency "rspec-its", "~> 1.3"
  spec.add_development_dependency "rspec_junit_formatter", "~> 0.4"
  spec.add_development_dependency "timecop", "~> 0.9"
  spec.add_development_dependency "webmock", "~> 3.14"
  spec.metadata["rubygems_mfa_required"] = "true"
end
