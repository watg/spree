require 'spec_helper'

# In this file, we want to test that the controller helpers function correctly
# So we need to use one of the controllers inside Spree.
# ProductsController is good.
describe Spree::ProductPagesController do

  before do
    expect(I18n).to receive(:available_locales).and_return([:en, :de]).at_least(1).times
    Spree::Frontend::Config[:locale] = :de
  end

  after do
    Spree::Frontend::Config[:locale] = :en
    I18n.locale = :en
  end

  # Regression test for #1184
  it "sets the default locale based off Spree::Frontend::Config[:locale]" do
    I18n.locale.should == :en
    spree_get :show
    I18n.locale.should == :de
  end

end
