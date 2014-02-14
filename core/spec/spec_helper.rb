# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
#require 'rspec/autorun'


# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

require 'spree/testing_support/authorization_helpers'
require 'spree/testing_support/preferences'
require 'spree/testing_support/controller_requests'
require 'spree/testing_support/flash'
require 'spree/testing_support/url_helpers'
require 'spree/testing_support/order_walkthrough'

# For the Api controller tests
require 'spree/api/testing_support/helpers.rb'
require 'spree/api/testing_support/setup.rb'

require 'factories'
require 'webmock/rspec'

RSpec.configure do |config|

  config.color = true
  config.mock_with :rspec
  config.backtrace_exclusion_patterns = [
    /\/lib\d*\/ruby\//,
    /bin\//,
    /gems/,
    /spec\/spec_helper\.rb/,
    /lib\/rspec\/(core|expectations|matchers|mocks)/
  ]

  config.include FactoryGirl::Syntax::Methods

  # spree helper
  config.include Spree::TestingSupport::AuthorizationHelpers::Request, type: :controller
  # config.include Spree::TestingSupport::ControllerRequests, type: :controller
  config.extend Watg::Authentication, type: :controller

  config.include Spree::Api::TestingSupport::Helpers
  config.extend Spree::Api::TestingSupport::Setup

  config.include Spree::TestingSupport::Preferences
  config.include Spree::TestingSupport::UrlHelpers
  config.include Spree::TestingSupport::ControllerRequests
  config.include Spree::TestingSupport::Flash

  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = "random"

  config.before(:suite) do
    #DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
    Delayed::Worker.delay_jobs = true
  end

  config.before(:each) do
    #DatabaseCleaner.start
    Spree::Api::Config[:requires_authentication] = true
    Delayed::Worker.delay_jobs = true
  end

  config.after(:each) do
    #DatabaseCleaner.clean
  end

  config.before(:each) do
    reset_spree_preferences
    #Spree::Preferences::Store.instance.clear_cache
  end
end

require 'rspec/expectations'

RSpec::Matchers.define :xml_match do |key,value|
  match do |actual|
    r = Regexp.new("#{key} .*>#{value}<\/#{key}")
    md = r.match(actual)
    !md.nil?
  end

  failure_message_for_should do |actual|
    "expected that XML to have node #{key} with value #{value}"
  end
end
