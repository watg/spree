require 'spec_helper'

describe Spree::Admin::ShippingMethodsController, type: :controller do
  stub_authorization!

  let(:shipping_method) { create(:shipping_method) }

  it "should not hard-delete shipping methods" do
    shipping_method.deleted_at.should be_nil
    spree_delete :destroy, :id => 1
    shipping_method.reload.deleted_at.should_not be_nil
  end
end
