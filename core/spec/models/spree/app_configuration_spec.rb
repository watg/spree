require 'spec_helper'

describe Spree::AppConfiguration do

  let (:prefs) { Rails.application.config.spree.preferences }

  it "should be available from the environment" do
    prefs.site_name = "TEST SITE NAME"
    expect(prefs.site_name).to eq "TEST SITE NAME"
  end

  it "should be available as Spree::Config for legacy access" do
    Spree::Config.site_name = "Spree::Config TEST SITE NAME"
    expect(Spree::Config.site_name).to eq "Spree::Config TEST SITE NAME"
  end

  it "uses base searcher class by default" do
    prefs.searcher_class = nil
    expect(prefs.searcher_class).to eq Spree::Core::Search::Base
  end

end

