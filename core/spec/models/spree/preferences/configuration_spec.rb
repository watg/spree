require 'spec_helper'

describe Spree::Preferences::Configuration do

  before :all do
    class AppConfig < Spree::Preferences::Configuration
      preference :color, :string, :default => :blue
    end
    @config = AppConfig.new
  end

  # Regression test for #3831
  context "with a rails cache id set" do
    before do
      allow(@config).to receive_messages :rails_cache_id => "cache"
    end

    it "can access the preference cache key" do
      expect(@config.preference_cache_key("foo")).to eql("cache/app_config/foo")
    end
  end

  context "with no rails cache id set" do
    it "does not prefix the preference cache key with a slash" do
      expect(@config.preference_cache_key("foo")).to eql("app_config/foo")
    end
  end

  it "has named methods to access preferences" do
    @config.color = 'orange'
    expect(@config.color).to eq 'orange'
  end

  it "uses [ ] to access preferences" do
    @config[:color] = 'red'
    expect(@config[:color]).to eq 'red'
  end

  it "uses set/get to access preferences" do
    @config.set :color, 'green'
    expect(@config.get(:color)).to eq 'green'
  end

end



