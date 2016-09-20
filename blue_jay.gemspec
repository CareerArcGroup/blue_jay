
# -*- encoding: utf-8 -*-
require File.expand_path("../lib/blue_jay/version", __FILE__)

Gem::Specification.new do |s|
  s.name	= 'blue_jay'
  s.date	= '2012-03-15'
  s.summary	= "BlueJay"
  s.version	= BlueJay::VERSION
  s.platform    = Gem::Platform::RUBY
  s.description = "Twitter library for TweetMyJobs and SNI"
  s.authors	= ["Stephen Roos"]
  s.email	= 'sroos@tweetmyjobs.com'
  s.homepage	= 'https://github.com/CareerArcGroup/blue_jay'
  s.license = 'MIT'

  s.add_dependency "oauth", "~> 0"
  s.add_dependency "json", "~> 1.8"
  s.add_dependency "multipart-post", "~> 1.2"
  s.add_development_dependency "bundler", "~> 1.12"
  s.add_development_dependency "rspec", "~> 3.5"
  s.add_development_dependency "simplecov", "~> 0"

  s.files = `git ls-files`.split("\n")
  s.executables = `git ls-files`.split("\n").map{|f| f =~ /^bin\/(.*)/ ? $1 : nil}.compact
  s.require_path = 'lib'
end
