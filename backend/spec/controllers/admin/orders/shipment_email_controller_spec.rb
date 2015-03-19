require 'spec_helper'

RSpec.describe Admin::Orders::ShipmentEmailController, type: :controller do
  stub_authorization!

  let(:order) { create(:order) }
  let(:updater) { Admin::Orders::UpdateShipmentEmailOnOrder }

  before do
    allow(updater).to receive(:run!)
  end

  describe "POST create" do
    it "redirects to the waiting orders page" do
      expect(spree_post :create, order_id: order.number)
        .to redirect_to([:admin, :waiting_orders])
    end

    it "renders JSON success" do
      spree_post :create, order_id: order.number, format: :js
      expect(response).to be_success
    end

    it "calls the shipment emailer updater" do
      spree_post :create, order_id: order.number
      expect(updater).to have_received(:run!).with(order: order, state: true)
    end
  end

  describe "DELETE destroy" do
    it "redirects to the waiting orders page" do
      expect(spree_delete :destroy, order_id: order.number)
        .to redirect_to([:admin, :waiting_orders])
    end

    it "renders JSON success" do
      spree_delete :destroy, order_id: order.number, format: :js
      expect(response).to be_success
    end

    it "calls the shipment emailer updater" do
      spree_delete :destroy, order_id: order.number
      expect(updater).to have_received(:run!).with(order: order, state: false)
    end
  end
end
