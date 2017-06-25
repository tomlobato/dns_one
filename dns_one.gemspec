# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dns_one/version'

Gem::Specification.new do |spec|
  spec.name          = "dns_one"
  spec.version       = DnsOne::VERSION
  spec.authors       = ["Tom Lobato"]
  spec.email         = ["tomlobato@gmail.com"]

  spec.summary       = %q{DNS server for many zones sharing only one or few records, written in Ruby.}
  spec.description   = %q{Instead having a complex data schema to assign record sets to individual DNS zones, dns_one assigns one or few record to many zones. Configure your zones in YML files and fetch your domains from a database or YML backend.}
  spec.homepage      = "http://dns-one.bettercall.io"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.14"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"

  spec.add_runtime_dependency "thor"
  spec.add_runtime_dependency "rubydns"
  spec.add_runtime_dependency "activerecord"

end
