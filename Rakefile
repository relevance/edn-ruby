#!/usr/bin/env rake
# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task default: :spec

task :irb do
  sh 'irb -I lib -r edn'
  sh 'reset'
end
