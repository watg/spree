require 'spec_helper'

describe Spree::AppConfiguration, :type => :model do

  let (:prefs) { Rails.application.config.spree.preferences }

  it "should be available from the environment" do
    prefs.layout = "my/layout"
    expect(prefs.layout).to eq "my/layout"
  end

  it "should be available as Spree::Config for legacy access" do
    Spree::Config.layout = "my/layout"
    expect(Spree::Config.layout).to eq "my/layout"
  end

end

