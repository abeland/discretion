# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'discretion/version'

Gem::Specification.new do |spec|
  spec.name          = 'discretion'
  spec.version       = Discretion::VERSION
  spec.authors       = ['Abe Land']
  spec.email         = ['codeclimbcoffee@gmail.com']

  spec.summary       = 'A simple privacy/authorization framework for Rails projects.'
  spec.description   = spec.summary
  spec.homepage      = 'https://github.com/abeland/discretion'
  spec.license       = 'MIT'

  spec.add_dependency 'activesupport', '~> 5.1', '>= 5.1.4'
  spec.add_dependency 'rails', '~>5'
  spec.add_dependency 'request_store', '~>1.4', '>= 1.4.1'
  spec.required_ruby_version = '>= 2.2.2'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'activerecord', '~> 5.1', '>= 5.1.4'
  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'factory_bot_rails', '~> 4.8', '>= 4.8.2'
  spec.add_development_dependency 'rake', '~> 10.5'
  spec.add_development_dependency 'rspec', '~> 3.7'
  spec.add_development_dependency 'rspec-rails', '~> 3.7', '>= 3.7.2'
  spec.add_development_dependency 'sqlite3', '~> 1.3', '>= 1.3.13'
end
