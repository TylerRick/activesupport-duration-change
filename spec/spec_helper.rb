require "bundler/setup"
require 'active_support' # Have to require first to avoid getting undefined method `deprecator' for ActiveSupport:Module
require "active_support/duration"
require 'active_support/core_ext/numeric/time' # for 3.seconds
require "active_support/duration/truncate"
require "active_support/duration/human_string"
require 'byebug' rescue nil

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

def durations(value)
  [
    build(value),
    seconds(value)
  ]
end

def build(value)
  ActiveSupport::Duration.build(value)
end

def seconds(value)
  ActiveSupport::Duration.seconds(value)
end
