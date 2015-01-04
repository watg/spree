# encoding: utf-8

require 'spec_helper'

class FakeCalculator < Spree::Calculator
  def compute(computable)
    5
  end
end

describe Spree::Order do
  let(:user) { stub_model(Spree::LegacyUser, :email => "spree@example.com") }
  let(:order) { stub_model(Spree::Order, :user => user) }

  before do
    allow(Spree::LegacyUser).to receive_messages(:current => mock_model(Spree::LegacyUser, :id => 123))
  end

  context "#prune_line_items" do

    let(:order_2)   { create(:order) }
    let!(:line_item1) { create(:line_item, :order => order_2, :quantity => 3 ) }

    before do
      order_2.line_items.reload
    end

    it "does not delete any line_items which have active variants" do
      order_2.prune_line_items
      expect(order_2.line_items.size).to eq 1
    end

    it "does deletes line_items which have deleted variants and calls touch" do
      line_item1.variant.delete
      line_item1.variant.save

      expect(order_2).to receive(:touch)
      order_2.prune_line_items
      expect(order_2.reload.line_items.size).to eq 0
    end

    it "does not delete line_items which have deleted variants but a completed state" do
      line_item1.variant.delete
      line_item1.variant.save

      order_2.completed_at = Time.now
      order_2.prune_line_items
      expect(order_2.reload.line_items.size).to eq 1
    end
  end

  context "#cost_price_total" do
    let!(:line_item1) { create(:line_item, :order => order, :quantity => 3 ) }

    it "returns total price of all line_items" do
      order.line_items.reload
      expect(order.cost_price_total).to eq 30
    end
  end

  context "#internal?" do
    it "returns true when order is marked as such" do
      order = build(:order, internal: true)
      expect(order.internal?).to be true
    end

    it "return false by default" do
      order = build(:order)
      expect(order.internal?).to be false
    end
  end

  context "#products" do
    before :each do
      @variant1 = mock_model(Spree::Variant, :product => "product1")
      @variant2 = mock_model(Spree::Variant, :product => "product2")
      @line_items = [mock_model(Spree::LineItem, :product => "product1", :variant => @variant1, :variant_id => @variant1.id, :quantity => 1),
                     mock_model(Spree::LineItem, :product => "product2", :variant => @variant2, :variant_id => @variant2.id, :quantity => 2)]
      allow(order).to receive_messages(:line_items => @line_items)
    end

    it "should return ordered products" do
      expect(order.products).to eq(['product1', 'product2'])
    end

    it "contains?" do
      expect(order.contains?(@variant1)).to be true
    end

    it "gets the quantity of a given variant" do
      expect(order.quantity_of(@variant1)).to eq(1)

      @variant3 = mock_model(Spree::Variant, :product => "product3")
      expect(order.quantity_of(@variant3)).to eq(0)
    end

    it "can find a line item matching a given variant" do
      expect(order.find_line_item_by_variant(@variant1)).not_to be_nil
      expect(order.find_line_item_by_variant(mock_model(Spree::Variant))).to be_nil
    end
  end

  context "#payments" do
    # For the reason of this test, please see spree/spree_gateway#132
    it "does not have inverse_of defined" do
      expect(Spree::Order.reflections[:payments].options[:inverse_of]).to be_nil
    end

    it "keeps source attributes after updating" do
      persisted_order = Spree::Order.create
      credit_card_payment_method = create(:credit_card_payment_method)
      attributes = {
        :payments_attributes => [
          {
            :payment_method_id => credit_card_payment_method.id,
            :source_attributes => {
              :name => "Ryan Bigg",
              :number => "41111111111111111111",
              :expiry => "01 / 15",
              :verification_value => "123"
            }
          }
        ]
      }

      persisted_order.update_attributes(attributes)
      expect(persisted_order.pending_payments.last.source.number).to be_present
    end
  end

  context "#generate_order_number" do
    it "should generate a random string" do
      expect(order.generate_order_number.is_a?(String)).to be true
      expect(order.generate_order_number.to_s.length > 0).to be true
    end
  end

  context "#associate_user!" do
    it "should associate a user with a persisted order" do
      order = FactoryGirl.create(:order_with_line_items, created_by: nil)
      user = FactoryGirl.create(:user)

      order.user = nil
      order.email = nil
      order.associate_user!(user)
      expect(order.user).to eq(user)
      expect(order.email).to eq(user.email)
      expect(order.created_by).to eq(user)

      # verify that the changes we made were persisted
      order.reload
      expect(order.user).to eq(user)
      expect(order.email).to eq(user.email)
      expect(order.created_by).to eq(user)
    end

    it "should not overwrite the created_by if it already is set" do
      creator = create(:user)
      order = FactoryGirl.create(:order_with_line_items, created_by: creator)
      user = FactoryGirl.create(:user)

      order.user = nil
      order.email = nil
      order.associate_user!(user)
      expect(order.user).to eq(user)
      expect(order.email).to eq(user.email)
      expect(order.created_by).to eq(creator)

      # verify that the changes we made were persisted
      order.reload
      expect(order.user).to eq(user)
      expect(order.email).to eq(user.email)
      expect(order.created_by).to eq(creator)
    end


    it "should associate a user with a non-persisted order" do
      order = Spree::Order.new

      expect do
        order.associate_user!(user)
      end.to change { [order.user, order.email] }.from([nil, nil]).to([user, user.email])
    end

    it "should not persist an invalid address" do
      address = Spree::Address.new
      order.user = nil
      order.email = nil
      order.ship_address = address
      expect do
        order.associate_user!(user)
      end.not_to change { address.persisted? }.from(false)
    end
  end

  context "#create" do
    it "should assign an order number" do
      order = Spree::Order.create
      expect(order.number).not_to be_nil
    end
  end

  describe "#can_ship?" do
    let(:order) { build(:order) }
    let(:valid_states) { %w(complete resumed awaiting_return returned) }

    it "is true for shippable states" do
      valid_states.each do |state|
        order.state = state
        expect(order.can_ship?).to be true
      end
    end

    it "is false for all other states" do
      other_states = Spree::Order.state_machine.states.map(&:name) -
        valid_states

      other_states.each do |state|
        order.state = state
        expect(order.can_ship?).to be false
      end
    end
  end

  context "checking if order is paid" do
    context "payment_state is paid" do
      before { allow(order).to receive_messages payment_state: 'paid' }
      it { expect(order).to be_paid }
    end

    context "payment_state is credit_owned" do
      before { allow(order).to receive_messages payment_state: 'credit_owed' }
      it { expect(order).to be_paid }
    end
  end

  context "creates shipments cost" do
    let(:shipment) { double }

    before { allow(order).to receive_messages shipments: [shipment] }

    it "update and persist totals" do
      expect(shipment).to receive :update_amounts
      expect(order.updater).to receive :update_shipment_total
      expect(order.updater).to receive :persist_totals

      order.set_shipments_cost
    end
  end

  context "#finalize!" do
    let(:order) { Spree::Order.create(email: 'test@example.com') }

    before do
      order.update_column :state, 'complete'
    end

    it "should set completed_at" do
      expect(order).to receive(:touch).with(:completed_at)
      order.finalize!
    end

    it "should sell inventory units" do
      order.shipments.each do |shipment|
        expect(shipment).to receive(:update!)
        expect(shipment).to receive(:finalize!)
      end
      order.finalize!
    end

    it "should decrease the stock for each variant in the shipment" do
      order.shipments.each do |shipment|
        expect(shipment.stock_location).to receive(:decrease_stock_for_variant)
      end
      order.finalize!
    end

    it "should change the shipment state to ready if order is paid" do
      Spree::Shipment.create(order: order)
      order.shipments.reload

      allow(order).to receive_messages(:paid? => true, :complete? => true, :physical_line_items => [double])
      order.finalize!
      order.reload # reload so we're sure the changes are persisted
      expect(order.shipment_state).to eq('ready')
    end

    after { Spree::Config.set :track_inventory_levels => true }
    it "should not sell inventory units if track_inventory_levels is false" do
      Spree::Config.set :track_inventory_levels => false
      expect(Spree::InventoryUnit).not_to receive(:sell_units)
      order.finalize!
    end

    it "should send an order confirmation email" do
      mail_message = double "Mail::Message"
      expect(Spree::OrderMailer).to receive(:confirm_email).with(order.id).and_return mail_message
      expect(mail_message).to receive :deliver
      order.finalize!
    end

    it "does not send a confirmation email for internal orders" do
      order.internal = true
      allow(Spree::OrderMailer).to receive(:confirm_email)
      order.finalize!
      expect(Spree::OrderMailer).not_to have_received(:confirm_email)
    end

    it "sets confirmation delivered when finalizing" do
      expect(order.confirmation_delivered?).to be false
      order.finalize!
      expect(order.confirmation_delivered?).to be true
    end

    it "should not send duplicate confirmation emails" do
      allow(order).to receive_messages(:confirmation_delivered? => true)
      expect(Spree::OrderMailer).not_to receive(:confirm_email)
      order.finalize!
    end

    it "should freeze all adjustments" do
      # Stub this method as it's called due to a callback
      # and it's irrelevant to this test
      allow(order).to receive :has_available_shipment
      allow(Spree::OrderMailer).to receive_message_chain :confirm_email, :deliver
      adjustments = [double]
      expect(order).to receive(:all_adjustments).and_return(adjustments)
      adjustments.each do |adj|
        expect(adj).to receive(:close)
      end
      order.finalize!
    end

    context "order is considered risky" do
      before do
        allow(order).to receive_messages :is_risky? => true
      end

      it "should change state to risky" do
        expect(order).to receive(:considered_risky!)
        order.finalize!
      end

      context "and order is approved" do
        before do
          allow(order).to receive_messages :approved? => true
        end

        it "should leave order in complete state" do
          order.finalize!
          expect(order.state).to eq 'complete'
        end

      end
    end

    context "order is not considered risky" do
      before do
        allow(order).to receive_messages :is_risky? => false
      end

      it "should set completed_at" do
        order.finalize!
        expect(order.completed_at).to be_present
      end
    end
  end

  context "#process_payments!" do
    let(:payment) { stub_model(Spree::Payment) }
    before { allow(order).to receive_messages :pending_payments => [payment], :total => 10 }

    it "should process the payments" do
      expect(payment).to receive(:process!)
      expect(order.process_payments!).to be_truthy
    end

    it "should return false if no pending_payments available" do
      allow(order).to receive_messages :pending_payments => []
      expect(order.process_payments!).to be false
    end

    context "when a payment raises a GatewayError" do
      before { expect(payment).to receive(:process!).and_raise(Spree::Core::GatewayError) }

      it "should return true when configured to allow checkout on gateway failures" do
        Spree::Config.set :allow_checkout_on_gateway_error => true
        expect(order.process_payments!).to be true
      end

      it "should return false when not configured to allow checkout on gateway failures" do
        Spree::Config.set :allow_checkout_on_gateway_error => false
        expect(order.process_payments!).to be false
      end

    end
  end

  context "#outstanding_balance" do
    it "should return positive amount when payment_total is less than total" do
      order.payment_total = 20.20
      order.total = 30.30
      expect(order.outstanding_balance).to eq(10.10)
    end
    it "should return negative amount when payment_total is greater than total" do
      order.total = 8.20
      order.payment_total = 10.20
      expect(order.outstanding_balance).to be_within(0.001).of(-2.00)
    end

  end

  context "#outstanding_balance?" do
    it "should be true when total greater than payment_total" do
      order.total = 10.10
      order.payment_total = 9.50
      expect(order.outstanding_balance?).to be true
    end
    it "should be true when total less than payment_total" do
      order.total = 8.25
      order.payment_total = 10.44
      expect(order.outstanding_balance?).to be true
    end
    it "should be false when total equals payment_total" do
      order.total = 10.10
      order.payment_total = 10.10
      expect(order.outstanding_balance?).to be false
    end
  end

  context "#completed?" do
    it "should indicate if order is completed" do
      order.completed_at = nil
      expect(order.completed?).to be false

      order.completed_at = Time.now
      expect(order.completed?).to be true
    end
  end

  it 'is backordered if one of the shipments is backordered' do
    allow(order).to receive_messages(:shipments => [mock_model(Spree::Shipment, :backordered? => false),
                              mock_model(Spree::Shipment, :backordered? => true)])
    expect(order).to be_backordered
  end

  it 'is awaiting_feed if one of the shipments is awaiting_feed' do
    allow(order).to receive_messages(:shipments => [mock_model(Spree::Shipment, :awaiting_feed? => false),
                              mock_model(Spree::Shipment, :awaiting_feed? => true)])
    expect(order).to be_awaiting_feed
  end

  context "#allow_checkout?" do
    it "should be true if there are line_items in the order" do
      allow(order).to receive_message_chain(:line_items, :count => 1)
      expect(order.checkout_allowed?).to be true
    end
    it "should be false if there are no line_items in the order" do
      allow(order).to receive_message_chain(:line_items, :count => 0)
      expect(order.checkout_allowed?).to be false
    end
  end

  context "#amount" do
    before do
      @order = create(:order, :user => user)
      @order.line_items = [create(:line_item, :price => 1.0, :quantity => 2),
                           create(:line_item, :price => 1.0, :quantity => 1)]
    end
    it "should return the correct lum sum of items" do
      expect(@order.amount).to eq(3.0)
    end
  end

  context "#can_cancel?" do
    it "should be false for completed order in the canceled state" do
      order.state = 'canceled'
      order.shipment_state = 'ready'
      order.completed_at = Time.now
      expect(order.can_cancel?).to be false
    end

    it "should be true for completed order with no shipment" do
      order.state = 'complete'
      order.shipment_state = nil
      order.completed_at = Time.now
      expect(order.can_cancel?).to be true
    end
  end

  context "#send_cancel_email" do
    let(:deliverable) { double("Deliverable", deliver: true) }

    before do
      allow(Spree::OrderMailer).to receive(:cancel_email).and_return(deliverable)
    end

    it "sends the cancel email" do
      order.send(:send_cancel_email)
      expect(Spree::OrderMailer).to have_received(:cancel_email).with(order.id)
    end

    it "does not send email for internal orders" do
      order.internal = true
      order.send(:send_cancel_email)
      expect(Spree::OrderMailer).not_to have_received(:cancel_email)
    end
  end

  context "insufficient_stock_lines" do
    let(:line_item) { Spree::LineItem.new(currency: order.currency) }

    before do
      line_item.errors[:quantity] << "Insufficient stock error"
      order.line_items << line_item
    end

    it "should return line_items that have insufficient stock on hand" do
      expect_any_instance_of(Spree::Stock::AvailabilityValidator).to receive(:validate_order).with(order)
      out_of_stock_lines = order.insufficient_stock_lines
      expect(out_of_stock_lines.size).to eq 1
      expect(out_of_stock_lines).to include line_item
    end
  end

  context "empty!" do
    let(:order) { stub_model(Spree::Order, item_count: 2) }

    before do
      allow(order).to receive_messages(:line_items => line_items = [1, 2])
      allow(order).to receive_messages(:adjustments => adjustments = [])
    end

    it "clears out line items, adjustments and update totals" do
      expect(order.line_items).to receive(:destroy_all)
      expect(order.adjustments).to receive(:destroy_all)
      expect(order.shipments).to receive(:destroy_all)
      expect(order.updater).to receive(:update_totals)
      expect(order.updater).to receive(:persist_totals)

      order.empty!
      expect(order.item_total).to eq 0
    end
  end

  context "#display_outstanding_balance" do
    it "returns the value as a spree money" do
      allow(order).to receive(:outstanding_balance) { 10.55 }
      expect(order.display_outstanding_balance).to eq(Spree::Money.new(10.55))
    end
  end

  context "#display_item_total" do
    it "returns the value as a spree money" do
      allow(order).to receive(:item_total) { 10.55 }
      expect(order.display_item_total).to eq(Spree::Money.new(10.55))
    end
  end

  context "#display_adjustment_total" do
    it "returns the value as a spree money" do
      order.adjustment_total = 10.55
      expect(order.display_adjustment_total).to eq(Spree::Money.new(10.55))
    end
  end

  context "#display_total" do
    it "returns the value as a spree money" do
      order.total = 10.55
      expect(order.display_total).to eq(Spree::Money.new(10.55))
    end
  end

  context "#currency" do
    context "when object currency is ABC" do
      before { order.currency = "ABC" }

      it "returns the currency from the object" do
        expect(order.currency).to eq("ABC")
      end
    end

    context "when object currency is nil" do
      before { order.currency = nil }

      it "returns the globally configured currency" do
        expect(order.currency).to eq("USD")
      end
    end
  end

  # Regression tests for #2179
  context "#merge!" do
    let(:variant) { create(:variant) }
    let(:order_1) { Spree::Order.create }
    let(:order_2) { Spree::Order.create }

    it "destroys the other order" do
      order_1.merge!(order_2)
      expect { order_2.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    context "user is provided" do
      it "assigns user to new order" do
        order_1.merge!(order_2, user)
        expect(order_1.user).to eq user
      end
    end

    context "merging together two orders with line items for the same variant" do
      before do
        order_1.contents.add(variant, 1)
        order_2.contents.add(variant, 1)
      end

      specify do
        order_1.merge!(order_2)
        order_1.line_items.reload
        expect(order_1.line_items.count).to eq(1)

        line_item = order_1.line_items.first
        expect(line_item.quantity).to eq(2)
        expect(line_item.variant_id).to eq(variant.id)
      end
    end

    context "merging together two orders with different line items" do
      let(:variant_2) { create(:variant) }

      before do
        order_1.contents.add(variant, 1)
        order_2.contents.add(variant_2, 1)
      end

      specify do
        order_1.merge!(order_2)
        line_items = order_1.line_items
        expect(line_items.count).to eq(2)

        expect(order_1.item_count).to eq 2
        expect(order_1.item_total).to eq line_items.map(&:amount).sum

        # No guarantee on ordering of line items, so we do this:
        expect(line_items.pluck(:quantity)).to match_array([1, 1])
        expect(line_items.pluck(:variant_id)).to match_array([variant.id, variant_2.id])
      end
    end
  end

  context "#confirmation_required?" do

    # Regression test for #4117
    it "is required if the state is currently 'confirm'" do
      order = Spree::Order.new
      assert !order.confirmation_required?
      order.state = 'confirm'
      assert order.confirmation_required?
    end

    context 'Spree::Config[:always_include_confirm_step] == true' do

      before do
        Spree::Config[:always_include_confirm_step] = true
      end

      it "returns true if payments empty" do
        order = Spree::Order.new
        assert order.confirmation_required?
      end
    end

    context 'Spree::Config[:always_include_confirm_step] == false' do

      it "returns false if payments empty and Spree::Config[:always_include_confirm_step] == false" do
        order = Spree::Order.new
        assert !order.confirmation_required?
      end

      it "does not bomb out when an order has an unpersisted payment" do
        order = Spree::Order.new
        order.payments.build
        assert !order.confirmation_required?
      end
    end
  end

  # Regression test for #2191
  context "when an order has an adjustment that zeroes the total, but another adjustment for shipping that raises it above zero" do
    let!(:persisted_order) { create(:order) }
    let!(:line_item) { create(:line_item) }
    let!(:shipping_method) do
      sm = create(:shipping_method)
      sm.calculator.preferred_amount = [{type: :integer, name: "USD", value: 10}]
      sm.save
      sm
    end

    before do
      # Don't care about available payment methods in this test
      allow(persisted_order).to receive_messages(:has_available_payment => false)
      persisted_order.line_items << line_item
      create(:adjustment, :amount => -line_item.amount, :label => "Promotion", :adjustable => line_item)
      persisted_order.state = 'delivery'
      persisted_order.save # To ensure new state_change event
    end

    it "transitions from delivery to payment" do
      allow(persisted_order).to receive_messages(payment_required?: true)
      persisted_order.next!
      expect(persisted_order.state).to eq("payment")
    end
  end

  context "payment required?" do
    let(:order) { Spree::Order.new }

    context "total is zero" do
      it { expect(order.payment_required?).to be false }
    end

    context "total > zero" do
      before { allow(order).to receive_messages(total: 1) }
      it { expect(order.payment_required?).to be true }
    end
  end

  context "add_update_hook" do
    before do
      Spree::Order.class_eval do
        register_update_hook :add_awesome_sauce
      end
    end

    after do
      Spree::Order.update_hooks = Set.new
    end

    it "calls hook during update" do
      order = create(:order)
      expect(order).to receive(:add_awesome_sauce)
      order.update!
    end

    it "calls hook during finalize" do
      order = create(:order)
      expect(order).to receive(:add_awesome_sauce)
      order.finalize!
    end
  end

  context "ensure shipments will be updated" do
    before { Spree::Shipment.create!(order: order) }

    it "destroys current shipments" do
      order.ensure_updated_shipments
      expect(order.shipments).to be_empty
    end

    it "puts order back in address state" do
      order.ensure_updated_shipments
      expect(order.state).to eql "address"
    end

    it "resets shipment_total" do
      order.update_column(:shipment_total, 5)
      order.ensure_updated_shipments
      expect(order.shipment_total).to eq(0)
    end

    context "except when order is completed, that's OrderInventory job" do
      it "doesn't touch anything" do
        allow(order).to receive_messages completed?: true
        order.update_column(:shipment_total, 5)
        order.shipments.create!

        expect {
          order.ensure_updated_shipments
        }.not_to change { order.shipment_total }

        expect {
          order.ensure_updated_shipments
        }.not_to change { order.shipments }

        expect {
          order.ensure_updated_shipments
        }.not_to change { order.state }
      end
    end
  end

  describe ".tax_address" do
    before { Spree::Config[:tax_using_ship_address] = tax_using_ship_address }
    subject { order.tax_address }

    context "when tax_using_ship_address is true" do
      let(:tax_using_ship_address) { true }

      it 'returns ship_address' do
        expect(subject).to eq(order.ship_address)
      end
    end

    context "when tax_using_ship_address is not true" do
      let(:tax_using_ship_address) { false }

      it "returns bill_address" do
        expect(subject).to eq(order.bill_address)
      end
    end
  end

  describe ".restart_checkout_flow" do
    it "updates the state column to the first checkout_steps value" do
      order = create(:order, :state => "delivery")
      expect(order.checkout_steps).to eql ["address", "delivery", "complete"]
      expect{ order.restart_checkout_flow }.to change{order.state}.from("delivery").to("address")
    end

    context "with custom checkout_steps" do
      it "updates the state column to the first checkout_steps value" do
        order = create(:order, :state => "delivery")
        expect(order).to receive(:checkout_steps).and_return ["custom_step", "address", "delivery", "complete"]
        expect{ order.restart_checkout_flow }.to change{order.state}.from("delivery").to("custom_step")
      end
    end
  end

  describe ".is_risky?" do
    context "Not risky order" do
      let(:order) { FactoryGirl.create(:order, payments: [payment]) }
      context "with avs_response == D" do
        let(:payment) { FactoryGirl.create(:payment, avs_response: "D") }
        it "is not considered risky" do
          expect(order.is_risky?).to eq(false)
        end
      end

      context "with avs_response == M" do
        let(:payment) { FactoryGirl.create(:payment, avs_response: "M") }
        it "is not considered risky" do
          expect(order.is_risky?).to eq(false)
        end
      end

      context "with avs_response == ''" do
        let(:payment) { FactoryGirl.create(:payment, avs_response: "") }
        it "is not considered risky" do
          expect(order.is_risky?).to eq(false)
        end
      end

      context "with cvv_response_code == M" do
        let(:payment) { FactoryGirl.create(:payment, cvv_response_code: "M") }
        it "is not considered risky" do
          expect(order.is_risky?).to eq(false)
        end
      end

      context "with cvv_response_message == ''" do
        let(:payment) { FactoryGirl.create(:payment, cvv_response_message: "") }
        it "is not considered risky" do
          expect(order.is_risky?).to eq(false)
        end
      end
    end

    context "Risky order" do
      context "AVS response message" do
        let(:order) { FactoryGirl.create(:order, payments: [FactoryGirl.create(:payment, avs_response: "A")]) }
        it "returns true if the order has an avs_response" do
          expect(order.is_risky?).to eq(true)
        end
      end

      context "CVV response code" do
        let(:order) { FactoryGirl.create(:order, payments: [FactoryGirl.create(:payment, cvv_response_code: "N")]) }
        it "returns true if the order has an cvv_response_code" do
          expect(order.is_risky?).to eq(true)
        end
      end

      context "state == 'failed'" do
        let(:order) { FactoryGirl.create(:order, payments: [FactoryGirl.create(:payment, state: 'failed')]) }
        it "returns true if the order has state == 'failed'" do
          expect(order.is_risky?).to eq(true)
        end
      end
    end
  end

  context "is considered risky" do
    let(:order) do
      order = FactoryGirl.create(:completed_order_with_pending_payment)
      order.considered_risky!
      order
    end

    it "can be approved by a user" do
      expect(order).to receive(:approve!)
      order.approved_by(stub_model(Spree::LegacyUser, id: 1))
      expect(order.approver_id).to eq(1)
      expect(order.approved_at).to be_present
      expect(order.approved?).to be true
    end
  end


  # Regression tests for #4072
  context "#state_changed" do
    let(:order) { FactoryGirl.create(:order) }

    it "logs state changes" do
      order.update_column(:payment_state, 'balance_due')
      order.payment_state = 'paid'
      expect(order.state_changes).to be_empty
      order.state_changed('payment')
      state_change = order.state_changes.find_by(:name => 'payment')
      expect(state_change.previous_state).to eq('balance_due')
      expect(state_change.next_state).to eq('paid')
    end

    it "does not do anything if state does not change" do
      order.update_column(:payment_state, 'balance_due')
      expect(order.state_changes).to be_empty
      order.state_changed('payment')
      expect(order.state_changes).to be_empty
    end
  end

  # Regression test for #4199
  context "#available_payment_methods" do
    it "includes frontend payment methods" do
      payment_method = Spree::PaymentMethod.create!({
        :name => "Fake",
        :active => true,
        :display_on => "front_end",
        :environment => Rails.env
      })
      expect(order.available_payment_methods).to include(payment_method)
    end

    it "includes 'both' payment methods" do
      payment_method = Spree::PaymentMethod.create!({
        :name => "Fake",
        :active => true,
        :display_on => "both",
        :environment => Rails.env
      })
      expect(order.available_payment_methods).to include(payment_method)
    end

    it "does not include a payment method twice if display_on is blank" do
      Spree::PaymentMethod.delete_all
      payment_method = Spree::PaymentMethod.create!({
        :name => "Fake",
        :active => true,
        :display_on => "",
        :environment => Rails.env
      })
      expect(order.available_payment_methods.count).to eq(1)
      expect(order.available_payment_methods).to include(payment_method)
    end
  end

  context "#apply_free_shipping_promotions" do
    it "calls out to the FreeShipping promotion handler" do
      shipment = double('Shipment')
      allow(order).to receive_messages :shipments => [shipment]
      expect(Spree::PromotionHandler::FreeShipping).to receive(:new).and_return(handler = double)
      expect(handler).to receive(:activate)

      expect(Spree::ItemAdjustments).to receive(:new).with(shipment).and_return(adjuster = double)
      expect(adjuster).to receive(:update)

      expect(order.updater).to receive(:update_shipment_total)
      expect(order.updater).to receive(:persist_totals)
      order.apply_free_shipping_promotions
    end
  end

  # Regression test for #4923
  context "locking" do
    let(:order) { Spree::Order.create } # need a persisted in order to test locking

    it 'can lock' do
      expect { order.with_lock {} }.to_not raise_error
    end
  end
end
