require 'spec_helper'

class FakesController < ApplicationController
  include Spree::Core::ControllerHelpers::Order
end

describe Spree::Core::ControllerHelpers::Order, type: :controller do
  controller(FakesController) {}

  let(:user) { create(:user) }
  let(:order) { create(:order, user: user) }
  let(:store) { create(:store) }

  describe '#set_current_order' do
    let(:incomplete_order) { create(:order, user: user) }
    before { allow(controller).to receive(:try_spree_current_user).and_return(user) }

    context 'when current order not equal to users incomplete orders' do
      before do
        allow(user).to receive(:last_incomplete_spree_order).and_return(incomplete_order)
        allow(controller).to receive(:current_order).and_return(order)
        session[:order_id] = order.id
      end

      it 'calls Spree::Order#merge! method' do
        expect(order).to receive(:merge!).with(incomplete_order, user)
        controller.set_current_order
      end

      it 'calls Spree::Order#reactive_gift_cards method' do
        expect(incomplete_order).to receive(:reactivate_gift_cards!)
        controller.set_current_order
      end

    end
  end

end
