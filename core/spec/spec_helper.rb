if ENV["COVERAGE"]
  # Run Coverage report
  require 'simplecov'
  SimpleCov.start do
    add_group 'Controllers', 'app/controllers'
    add_group 'Helpers', 'app/helpers'
    add_group 'Mailers', 'app/mailers'
    add_group 'Models', 'app/models'
    add_group 'Views', 'app/views'
    add_group 'Libraries', 'lib'
  end
end

# This file is copied to ~/spec when you run 'ruby script/generate rspec'
# from the project root directory.
ENV["RAILS_ENV"] ||= 'test'

begin
  require File.expand_path("../../../../../config/environment", __FILE__)
rescue LoadError
  require File.expand_path("../../../config/environment", __FILE__ )
end

require 'rspec/rails'
require 'database_cleaner'
# require 'ffaker'

require File.expand_path("../support/big_decimal", __FILE__)
require File.expand_path("../support/test_gateway", __FILE__)

if ENV["CHECK_TRANSLATIONS"]
  require "spree/testing_support/i18n"
end

require 'spree/testing_support/factories'
require 'spree/testing_support/preferences'
require 'spree/testing_support/image_stub'

RSpec.configure do |config|
  config.color = true
  config.infer_spec_type_from_file_location!
  config.mock_with :rspec
  config.backtrace_exclusion_patterns = [
    /\/lib\d*\/ruby\//,
    /bin\//,
    /gems/,
    /custom_plan/,
    /spec\/spec_helper\.rb/,
    /lib\/rspec\/(core|expectations|matchers|mocks)/
  ]
  config.fixture_path = File.join(File.expand_path(File.dirname(__FILE__)), "fixtures")

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, comment the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  config.before(:each) do
    Rails.cache.clear
    reset_spree_preferences
  end

  config.include FactoryGirl::Syntax::Methods
  config.include Spree::TestingSupport::Preferences

  config.fail_fast = ENV['FAIL_FAST'] || false

end
