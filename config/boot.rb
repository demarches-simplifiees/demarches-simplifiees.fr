# frozen_string_literal: true

ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require "logger" # force logger to be loaded before bundler/setup https://github.com/rails/rails/pull/54264#issuecomment-2596149819, to be removed after rails 7.2.x 
require "bundler/setup" # Set up gems listed in the Gemfile.
require "bootsnap/setup" # Speed up boot time by caching expensive operations.
