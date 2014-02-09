$:.unshift File.expand_path("../lib", __FILE__)
require "capistrano_rails_recipes/version"

Gem::Specification.new do |s|
  s.name     = "capistrano_rails_recipes"
  s.version  = CapistranoRailsRecipes::VERSION

  s.authors = ["Dmitry Galinsky", "Alex Dubovskoy"]
  s.email    = "dubovskoy.a@gmail.com"
  s.homepage = "https://github.com/dubadub/capistrano_rails_recipes"
  s.summary  = "Capistrano recipes for rails app"

  s.description = s.summary

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")

  s.require_paths = ["lib"]

  s.add_runtime_dependency("capistrano", ["= 2.15.5"])
  s.add_runtime_dependency("foreman", [">= 0"])
  s.add_runtime_dependency("foreman_export_runitu", [">= 0"])
  s.add_runtime_dependency("whenever", ["~> 0.8.4"])
end
