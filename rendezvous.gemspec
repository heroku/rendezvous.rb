# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rendezvous/version'

Gem::Specification.new do |gem|
  gem.name          = "rendezvous"
  gem.version       = Rendezvous::VERSION
  gem.authors       = ["geemus"]
  gem.email         = ["geemus@gmail.com"]
  gem.description   = %q{Client for interacting with Heroku processes.}
  gem.summary       = %q{Client for interacting with Heroku processes.}
  gem.homepage      = "http://github.com/heroku/rendezvous.rb"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
end
