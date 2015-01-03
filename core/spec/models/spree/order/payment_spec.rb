require 'spec_helper'

module Spree
  describe Spree::Order do
    let(:order) { stub_model(Spree::Order) }
    let(:updater) { Spree::OrderUpdater.new(order) }

    before do
      # So that Payment#purchase! is called during processing
      Spree::Config[:auto_capture] = true

      allow(order).to receive_message_chain(:line_items, :empty?).and_return(false)
      allow(order).to receive_messages :total => 100
    end

    it 'processes all payments' do
      payment_1 = create(:payment, :amount => 50)
      payment_2 = create(:payment, :amount => 50)
      allow(order).to receive(:pending_payments).and_return([payment_1, payment_2])

      order.process_payments!
      updater.update_payment_state
      expect(order.payment_state).to eq('paid')

      expect(payment_1).to be_completed
      expect(payment_2).to be_completed
    end

    it 'does not go over total for order' do
      payment_1 = create(:payment, :amount => 50)
      payment_2 = create(:payment, :amount => 50)
      payment_3 = create(:payment, :amount => 50)
      allow(order).to receive(:pending_payments).and_return([payment_1, payment_2, payment_3])

      order.process_payments!
      updater.update_payment_state
      expect(order.payment_state).to eq('paid')

      expect(payment_1).to be_completed
      expect(payment_2).to be_completed
      expect(payment_3).to be_checkout
    end

    it "does not use failed payments" do
      DatabaseCleaner.clean # otherwise stack level too deep error with :state => 'failed'
      payment_1 = create(:payment, :amount => 50)
      payment_2 = create(:payment, :amount => 50, :state => 'failed')
      allow(order).to receive(:pending_payments).and_return([payment_1])

      expect(payment_2).not_to receive(:process!)

      order.process_payments!
    end
  end
end
