# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "sidekiq_process_killer/version"

Gem::Specification.new do |spec|
  spec.name          = "sidekiq_process_killer"
  spec.version       = SidekiqProcessKiller::VERSION
  spec.authors       = ["Shayon Mukherjee"]
  spec.email         = ["dev@shayon.me"]

  spec.summary       = "Simple process killer for sidekiq to avoid memory leaks and/or bloats"
  spec.description   = "SidekiqProcessKiller plugs into Sidekiq's middleware and kills a process if its processing beyond the supplied RSS threshold. Since, this plugs into the middleware the check is performed after each job."
  spec.homepage      = "htts://github.com/shayonj/sidekiq_process_killer"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"

  spec.add_dependency "get_process_mem"
  spec.add_dependency "sidekiq"
end
