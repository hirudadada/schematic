require 'bundler/setup'
Bundler.setup
require 'fileutils'
require 'mysql2'
require 'yaml'
require 'logger'

# Add the lib directory to the load path
$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

# First load helpers
require_relative 'support/fixtures_helper'

# Then load the shared contexts in order
require_relative 'support/shared_contexts/routine_load_context'
require_relative 'support/shared_contexts/error_handling_routine_load_context'
require_relative 'support/shared_contexts/gitops_generator_context'

# Load remaining support files
Dir[File.expand_path('support/shared_examples/**/*.rb', __dir__)].each { |f| require f }

RSpec.configure do |config|
  # Include FixturesHelper in all example groups
  config.include FixturesHelper
  
  # Extend FixturesHelper for class methods
  config.extend FixturesHelper

  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:suite) do
    # Ensure fixtures directory exists
    FileUtils.mkdir_p(FixturesHelper.fixture_path('gitops/overlays/dev/configmap'))
    FixturesHelper.copy_migrations_to_fixtures
  end
end
