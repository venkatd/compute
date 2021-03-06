# -*- encoding: utf-8 -*-
require File.expand_path('../lib/compute/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Venkat Dinavahi"]
  gem.email         = ["vendiddy@gmail.com"]
  gem.description   = %q{ActiveRecord extension for providing computed fields.}
  gem.summary       = %q{
    Provides a compute DSL for creating ActiveRecord columns that are computed from other ones.
    Automatically keeps the columns up to date.
  }
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "compute"
  gem.require_paths = ["lib"]
  gem.version       = Compute::VERSION
  gem.required_ruby_version = '>= 1.9.3'

  gem.add_dependency "activerecord"

  gem.add_development_dependency "rspec"
  gem.add_development_dependency "sqlite3"
  gem.add_development_dependency "debugger"
  gem.add_development_dependency "with_model"
end
