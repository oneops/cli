$:.unshift File.expand_path("../lib", __FILE__)

require 'oneops/version'

Gem::Specification.new do |s|
  s.name        = 'oneops'
  s.version     = OO::VERSION
  s.author      = 'OneOps'
  s.email       = 'support@oneops.com'
  s.homepage    = 'http://www.oneops.com'
  s.summary     = 'OneOps API library and CLI'
  s.license	= 'Apache-2.0'
  s.description = 'Client library and CLI that provides access to the OneOps Cloud Application Management Platform.'
  s.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }

  s.platform         = Gem::Platform::RUBY
  s.extra_rdoc_files = %w(README.md LICENSE)

  s.add_dependency "activesupport", "~> 3.2"
  s.add_dependency "rest-client", "~> 1.6"
  s.add_dependency "netrc", "~> 0.7"
  s.add_dependency "thor", "~> 0.19"

  s.bindir       = 'bin'
  s.require_path = 'lib'
  s.files        = %w(LICENSE README.md Rakefile) + `git ls-files lib`.split("\n")
end
