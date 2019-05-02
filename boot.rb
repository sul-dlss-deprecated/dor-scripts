# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('Gemfile', __dir__)
require 'bundler/setup' # Set up gems listed in the Gemfile.
Bundler.require(:default)

require 'optparse'

# either environment variable config is ok for backwards compatibility with robot environment setting format
environment = ENV['ENV'] || ENV['ROBOT_ENVIRONMENT']
Config.load_and_set_settings(Config.setting_files(File.expand_path('config', __dir__), environment))

require_relative 'lib/common.rb'
require_relative 'lib/dor_config.rb'
