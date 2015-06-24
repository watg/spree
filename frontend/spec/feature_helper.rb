ENV["RAILS_ENV"] = 'features'
require "spec_helper"
require 'devise'

RSpec.configure do |config|
  config.include Spree::TestingSupport::ControllerRequests, :type => :controller
  config.include Devise::TestHelpers, :type => :controller
  config.include Rack::Test::Methods, :type => :feature
  config.include Capybara::DSL
  config.include FeatureHelpers
end
