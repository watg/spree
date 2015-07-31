require 'spec_helper'

describe Spree::Admin::ShippingMethodsController, :type => :controller do
  stub_authorization!

  let(:shipping_method) { create(:shipping_method) }

  it "should not hard-delete shipping methods" do
    expect(shipping_method.deleted_at).to be_nil
    spree_get :destroy, :id => shipping_method.id
    expect(shipping_method.reload.deleted_at).not_to be_nil
  end
end
