require "spec_helper"

describe Spree::Admin::Orders::HoldsController, type: :controller do
  stub_authorization!

  let(:order) { create(:order) }

  describe "GET new" do
    it "is successful" do
      spree_get :new, order_id: order.to_param
      expect(response).to be_success
    end

    it "assigns the order" do
      spree_get :new, order_id: order.to_param
      expect(assigns[:order]).to eq(order)
    end
  end

  describe "POST create" do
    let(:reason) { "this is a reason why it is being put on hold" }
    let(:user) { create(:user) }
    let(:params) { { order_id: order.to_param, reason: reason, type: "warehouse" } }
    let(:valid) { true }
    let(:service_result) { double(Spree::HoldService, valid?: valid) }

    before do
      allow(controller).to receive_messages spree_current_user: user
      allow(Spree::HoldService).to receive(:run).and_return(service_result)
    end

    it "puts the order on hold" do
      spree_post :create, params
      expect(Spree::HoldService).to have_received(:run).with(
        order:  order,
        reason: reason,
        user:   user,
        type:   "warehouse"
      )
    end

    context "when the hold is successful" do
      let(:valid) { true }

      it "redirects to the order page" do
        spree_post :create, params
        expect(response).to redirect_to([:edit, :admin, order])
      end

      it "sets a flash success message" do
        spree_post :create, params
        expect(flash[:success]).not_to be_blank
        expect(flash[:error]).to be_blank
      end
    end

    context "when the hold fails" do
      let(:valid) { false }

      it "redisplays the form" do
        spree_post :create, params
        expect(response).to render_template(:new)
      end

      it "sets a flash error message" do
        spree_post :create, params
        expect(flash[:error]).not_to be_blank
        expect(flash[:success]).to be_blank
      end

      it "assigns the order" do
        spree_post :create, params
        expect(assigns[:order]).to eq(order)
      end
    end
  end

  describe "GET show" do
    let(:order) { create(:order, state: "warehouse_on_hold") }
    let(:order_note) { create(:order_note, order: order) }

    it "is successful" do
      spree_get :show, order_id: order.to_param, id: order_note.id
      expect(response).to be_success
    end

    it "assigns the order" do
      spree_get :show, order_id: order.to_param, id: order_note.id
      expect(assigns[:order]).to eq(order)
    end

    it "assigns the order note" do
      spree_get :show, order_id: order.to_param, id: order_note.id
      expect(assigns[:note]).to eq(order_note)
    end
  end

  describe "DELETE destroy" do
    let(:order) { create(:order, state: state) }

    context "when the order is on hold by warehouse" do
      let(:state) { :warehouse_on_hold }

      it "removes the order hold" do
        allow(Spree::Order).to receive(:find_by_number).with(order.number).and_return(order)
        expect(order).to receive(:remove_hold).and_call_original
        spree_delete :destroy, order_id: order.number, id: 1
        expect(order).to be_resumed
      end

      it "redirects to the order page" do
        spree_delete :destroy, order_id: order.number, id: 1
        expect(response).to redirect_to([:edit, :admin, order])
      end

      it "sets the flahs message" do
        spree_delete :destroy, order_id: order.number, id: 1
        expect(flash[:success]).to eq("Order #{order.number} no longer on hold")
      end
    end

    context "when the order is on hold by customer service" do
      let(:state) { :customer_service_on_hold }

      it "removes the order hold" do
        allow(Spree::Order).to receive(:find_by_number).with(order.number).and_return(order)
        expect(order).to receive(:remove_hold).and_call_original
        spree_delete :destroy, order_id: order.number, id: 1
        expect(order).to be_resumed
      end

      it "redirects to the order page" do
        spree_delete :destroy, order_id: order.number, id: 1
        expect(response).to redirect_to([:edit, :admin, order])
      end

      it "sets the flahs message" do
        spree_delete :destroy, order_id: order.number, id: 1
        expect(flash[:success]).to eq("Order #{order.number} no longer on hold")
      end
    end
  end
end
