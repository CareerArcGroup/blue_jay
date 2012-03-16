require 'bundler'
Bundler::GemHelper.install_tasks

require 'rake'
require 'rspec/core/rake_task'

desc 'Default: run specs.'
task :default => :spec
task :test => :spec

desc "Run specs"
RSpec::Core::RakeTask.new do |t|
	# Put spec opts in a file named .rspec in root
end

desc "Generate code coverage"
RSpec::Core::RakeTask.new(:coverage) do |t|
	t.rcov = true
	t.rcov_opts = %w( --exclude spec )
end