# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'on_form/version'

Gem::Specification.new do |spec|
  spec.name          = "on_form"
  spec.version       = OnForm::VERSION
  spec.authors       = ["Will Bryant"]
  spec.email         = ["will.bryant@gmail.com"]

  spec.summary       = %q{A pragmatism-first library to help Rails applications migrate from complex nested attribute models to tidy form objects.}
  spec.description   = %q{Our goal is that you can migrate large forms to OnForm incrementally, without having to refactor large amounts of code in a single release.}
  spec.homepage      = "https://github.com/powershop/on_form"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activemodel",  ENV["RAILS_VERSION"]
  spec.add_dependency "activerecord", ENV["RAILS_VERSION"]
  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "sqlite3"
end
