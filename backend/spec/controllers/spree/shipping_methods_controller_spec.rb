require "spec_helper"

describe Spree::Admin::ShippingMethodsController, type: :controller do
  stub_authorization!

  let(:shipping_method) { create(:shipping_method) }

  it "does not hard-delete shipping methods" do
    expect(shipping_method.deleted_at).to be_nil
    spree_delete :destroy, id: shipping_method.id
    expect(shipping_method.reload.deleted_at).not_to be_nil
  end
end
