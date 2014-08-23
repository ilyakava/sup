# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)
require 'rspec/core/rake_task'
Sup::Application.load_tasks
RSpec::Core::RakeTask.new(:spec)
# Exclude slow tests
RSpec::Core::RakeTask.new(:fspec) do |t|
  t.rspec_opts = '--tag ~speed:slow'
end

desc 'Run RuboCop'
task :rubocop do
  sh 'bundle exec rubocop'
end

task default: [:rubocop, :spec]
