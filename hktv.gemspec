# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hktv/version'

Gem::Specification.new do |spec|
  spec.name          = "hktv"
  spec.version       = HKTV::VERSION
  spec.authors       = ["Francis Chong"]
  spec.email         = ["francis@ignition.hk"]
  spec.summary       = %q{Find and download HKTV videos.}
  spec.description   = %q{Command line utilities to find and download HKTV videos.}
  spec.homepage      = "https://github.com/siuying/ruby-hktv"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "pry", '~> 0'
  spec.add_development_dependency "rspec", '~> 0'
  spec.add_development_dependency "vcr", '~> 0'
  spec.add_development_dependency "webmock", '~> 0'

  spec.add_dependency "httparty", "~> 0.13", '>= 0.13.1'
  spec.add_dependency "retriable", "~> 1.4", '>= 1.4.1'
  spec.add_dependency 'commander', "~> 4.2", '>= 4.2.1'
end
