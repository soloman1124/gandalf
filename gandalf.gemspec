# -*- encoding: utf-8 -*-
require File.expand_path('../lib/gandalf/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Marty Zalega"]
  gem.email         = ["evil.marty@gmail.com"]
  gem.description   = %q{Simply delegates authentication to your own implementation.}
  gem.summary       = %q{Manage user authentication.}
  gem.homepage      = "http://github.com/everydayhero/gandalf"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test)/})
  gem.name          = "gandalf"
  gem.require_paths = ["lib"]
  gem.version       = Gandalf::VERSION

  gem.add_dependency 'rails', '>= 3.0.0'
end
