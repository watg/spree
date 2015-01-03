require 'spec_helper'
require 'spree/testing_support/order_walkthrough'

describe Spree::Order do
  let(:order) { Spree::Order.new }

  def assert_state_changed(order, from, to)
    state_change_exists = order.state_changes.where(:previous_state => from, :next_state => to).exists?
    assert state_change_exists, "Expected order to transition from #{from} to #{to}, but didn't."
  end

  context "with default state machine" do

    # Added, otherwise failures seem to occur, not sure why!!!
    before do
      @old_checkout_flow = Spree::Order.checkout_flow
    end
    after do
      Spree::Order.checkout_flow(&@old_checkout_flow)
    end

    let(:transitions) do
      [
        { :address => :delivery },
        { :delivery => :payment },
        { :payment => :confirm },
        { :confirm => :complete },
        { :payment => :complete },
        { :delivery => :complete }
      ]
    end

    it "has the following transitions" do
      transitions.each do |transition|
        transition = Spree::Order.find_transition(:from => transition.keys.first, :to => transition.values.first)
        expect(transition).not_to be_nil
      end
    end

    it "does not have a transition from delivery to confirm" do
      transition = Spree::Order.find_transition(:from => :delivery, :to => :confirm)
      expect(transition).to be_nil
    end

    it '.find_transition when contract was broken' do
      expect(Spree::Order.find_transition({foo: :bar, baz: :dog})).to be falsey
    end

    it '.remove_transition' do
      options = {:from => transitions.first.keys.first, :to => transitions.first.values.first}
      allow(Spree::Order).to receive(:next_event_transition).and_return([options])
      expect(Spree::Order.remove_transition(options)).to be_truthy
    end

    it '.remove_transition when contract was broken' do
      expect(Spree::Order.remove_transition(nil)).to be falsey
    end

    context "#checkout_steps" do
      context "when confirmation not required" do
        before do
          allow(order).to receive_messages :confirmation_required? => false
          allow(order).to receive_messages :payment_required? => true
        end

        specify do
          expect(order.checkout_steps).to eq(%w(address delivery payment complete))
        end
      end

      context "when confirmation required" do
        before do
          allow(order).to receive_messages :confirmation_required? => true
          allow(order).to receive_messages :payment_required? => true
        end

        specify do
          expect(order.checkout_steps).to eq(%w(address delivery payment confirm complete))
        end
      end

      context "when payment not required" do
        before { allow(order).to receive_messages :payment_required? => false }
        specify do
          expect(order.checkout_steps).to eq(%w(address delivery complete))
        end
      end

      context "when payment required" do
        before { allow(order).to receive_messages :payment_required? => true }
        specify do
          expect(order.checkout_steps).to eq(%w(address delivery payment complete))
        end
      end
    end

    it "starts out at cart" do
      expect(order.state).to eq("cart")
    end

    it "transitions to address" do
      order.line_items << FactoryGirl.create(:line_item)
      order.email = "user@example.com"
      order.next!
      assert_state_changed(order, 'cart', 'address')
      expect(order.state).to eq("address")
    end

    it "cannot transition to address without any line items" do
      expect(order.line_items).to be_blank
      expect { order.next! }.to raise_error(StateMachine::InvalidTransition, /#{Spree.t(:there_are_no_items_for_this_order)}/)
    end

    context "from address" do
      before do
        order.state = 'address'
        allow(order).to receive(:has_available_payment)
        shipment = FactoryGirl.create(:shipment, :order => order)
        order.email = "user@example.com"
        order.save!
      end

      it "updates totals" do
        allow(order).to receive_messages(:ensure_available_shipping_rates => true)
        line_item = FactoryGirl.create(:line_item, :price => 10, :adjustment_total => 10)
        order.line_items << line_item
        tax_rate = create(:tax_rate, :tax_category => line_item.tax_category, :amount => 0.05)
        allow(Spree::TaxRate).to receive_messages :match => [tax_rate]
        FactoryGirl.create(:tax_adjustment, :adjustable => line_item, :source => tax_rate)
        order.email = "user@example.com"
        order.next!
        expect(order.adjustment_total).to eq(0.5)
        expect(order.additional_tax_total).to eq(0.5)
        expect(order.included_tax_total).to eq(0)
        expect(order.total).to eq(10.5)
      end

      it "transitions to delivery" do
        allow(order).to receive_messages(:ensure_available_shipping_rates => true)
        order.next!
        assert_state_changed(order, 'address', 'delivery')
        expect(order.state).to eq("delivery")
      end

      context "cannot transition to delivery" do
        context "if there are no shipping rates for any shipment" do
          specify do
            transition = lambda { order.next! }
            expect(transition).to raise_error(StateMachine::InvalidTransition, /#{Spree.t(:items_cannot_be_shipped)}/)
          end
        end
      end
    end

    context "from delivery" do
      before do
        order.state = 'delivery'
        allow(order).to receive(:apply_free_shipping_promotions)
      end

      it "attempts to apply free shipping promotions" do
        expect(order).to receive(:apply_free_shipping_promotions)
        order.next!
      end

      context "with payment required" do
        before do
          allow(order).to receive_messages :payment_required? => true
        end

        it "transitions to payment" do
          expect(order).to receive(:set_shipments_cost)
          order.next!
          assert_state_changed(order, 'delivery', 'payment')
          expect(order.state).to eq('payment')
        end
      end

      context "without payment required" do
        before do
          allow(order).to receive_messages :payment_required? => false
        end

        it "transitions to complete" do
          order.next!
          expect(order.state).to eq("complete")
        end
      end

      context "correctly determining payment required based on shipping information" do
        let(:shipment) do
          FactoryGirl.create(:shipment)
        end

        before do
          # Needs to be set here because we're working with a persisted order object
          order.email = "test@example.com"
          order.save!
          order.shipments << shipment
        end

        context "with a shipment that has a price" do
          before do
            shipment.shipping_rates.first.update_column(:cost, 10)
            order.set_shipments_cost
          end

          it "transitions to payment" do
            order.next!
            expect(order.state).to eq("payment")
          end
        end

        context "with a shipment that is free" do
          before do
            shipment.shipping_rates.first.update_column(:cost, 0)
            order.set_shipments_cost
          end

          it "skips payment, transitions to complete" do
            order.next!
            expect(order.state).to eq("complete")
          end
        end
      end
    end

    context "from payment" do
      before do
        order.state = 'payment'
      end

      context "with confirmation required" do
        before do
          allow(order).to receive_messages :confirmation_required? => true
        end

        it "transitions to confirm" do
          order.next!
          assert_state_changed(order, 'payment', 'confirm')
          expect(order.state).to eq("confirm")
        end
      end

      context "without confirmation required" do
        before do
          allow(order).to receive_messages :confirmation_required? => false
          allow(order).to receive_messages :payment_required? => true
        end

        it "transitions to complete" do
          expect(order).to receive(:process_payments!).once.and_return true
          order.next!
          assert_state_changed(order, 'payment', 'complete')
          expect(order.state).to eq("complete")
        end
      end

      # Regression test for #2028
      context "when payment is not required" do
        before do
          allow(order).to receive_messages :payment_required? => false
        end

        it "does not call process payments" do
          expect(order).not_to receive(:process_payments!)
          order.next!
          assert_state_changed(order, 'payment', 'complete')
          expect(order.state).to eq("complete")
        end
      end
    end
  end

  context "subclassed order" do
    # This causes another test above to fail, but fixing this test should make
    #   the other test pass
    class SubclassedOrder < Spree::Order
      checkout_flow do
        go_to_state :payment
        go_to_state :complete
      end
    end

    skip "should only call default transitions once when checkout_flow is redefined" do
      order = SubclassedOrder.new
      allow(order).to receive_messages :payment_required? => true
      expect(order).to receive(:process_payments!).once
      order.state = "payment"
      order.next!
      assert_state_changed(order, 'payment', 'complete')
      expect(order.state).to eq("complete")
    end
  end

  context "re-define checkout flow" do
    before do
      @old_checkout_flow = Spree::Order.checkout_flow
      Spree::Order.class_eval do
        checkout_flow do
          go_to_state :payment
          go_to_state :complete
        end
      end
    end

    after do
      Spree::Order.checkout_flow(&@old_checkout_flow)
    end

    it "should not keep old event transitions when checkout_flow is redefined" do
      expect(Spree::Order.next_event_transitions).to eq([{:cart=>:payment}, {:payment=>:complete}])
    end

    it "should not keep old events when checkout_flow is redefined" do
      state_machine = Spree::Order.state_machine
      expect(state_machine.states.any? { |s| s.name == :address }).to be false
      known_states = state_machine.events[:next].branches.map(&:known_states).flatten
      expect(known_states).not_to include(:address)
      expect(known_states).not_to include(:delivery)
      expect(known_states).not_to include(:confirm)
    end
  end

  # Regression test for #3665
  context "with only a complete step" do
    before do
      @old_checkout_flow = Spree::Order.checkout_flow
      Spree::Order.class_eval do
        checkout_flow do
          go_to_state :complete
        end
      end
    end

    after do
      Spree::Order.checkout_flow(&@old_checkout_flow)
    end

    it "does not attempt to process payments" do
      allow(order).to receive_message_chain(:line_items, :present?).and_return(true)
      expect(order).not_to receive(:payment_required?)
      expect(order).not_to receive(:process_payments!)
      order.next!
      assert_state_changed(order, 'cart', 'complete')
    end

  end

  context "insert checkout step" do
    before do
      @old_checkout_flow = Spree::Order.checkout_flow
      Spree::Order.class_eval do
        insert_checkout_step :new_step, before: :address
      end
    end

    after do
      Spree::Order.checkout_flow(&@old_checkout_flow)
    end

    it "should maintain removed transitions" do
      transition = Spree::Order.find_transition(:from => :delivery, :to => :confirm)
      expect(transition).to be_nil
    end

    context "before" do
      before do
        Spree::Order.class_eval do
          insert_checkout_step :before_address, before: :address
        end
      end

      specify do
        order = Spree::Order.new
        expect(order.checkout_steps).to eq(%w(new_step before_address address delivery complete))
      end
    end

    context "after" do
      before do
        Spree::Order.class_eval do
          insert_checkout_step :after_address, after: :address
        end
      end

      specify do
        order = Spree::Order.new
        expect(order.checkout_steps).to eq(%w(new_step address after_address delivery complete))
      end
    end
  end

  context "remove checkout step" do
    before do
      @old_checkout_flow = Spree::Order.checkout_flow
      Spree::Order.class_eval do
        remove_checkout_step :address
      end
    end

    after do
      Spree::Order.checkout_flow(&@old_checkout_flow)
    end

    it "should maintain removed transitions" do
      transition = Spree::Order.find_transition(:from => :delivery, :to => :confirm)
      expect(transition).to be_nil
    end

    specify do
      order = Spree::Order.new
      expect(order.checkout_steps).to eq(%w(delivery complete))
    end
  end

  describe "payment processing" do
    # Turn off transactional fixtures so that we can test that
    # processing state is persisted.
    self.use_transactional_fixtures = false
    before(:all) { DatabaseCleaner.strategy = :truncation }
    after(:all) do
      DatabaseCleaner.clean
      DatabaseCleaner.strategy = :transaction
    end
    let(:order) { OrderWalkthrough.up_to(:payment) }
    let(:creditcard) { create(:credit_card) }
    let!(:payment_method) { create(:credit_card_payment_method, :environment => 'test') }

    it "does not process payment within transaction" do
      # Make sure we are not already in a transaction
      expect(ActiveRecord::Base.connection.open_transactions).to eq(0)

      expect_any_instance_of(Spree::Payment).to receive(:authorize!) do
        expect(ActiveRecord::Base.connection.open_transactions).to eq(0)
      end

      result = order.payments.create!({ :amount => order.outstanding_balance, :payment_method => payment_method, :source => creditcard })
      order.next!
    end
  end

  describe 'update_from_params' do
    let(:permitted_params) { {} }
    let(:params) { {} }

    it 'calls update_atributes without order params' do
      expect(order).to receive(:update_attributes).with({})
      order.update_from_params( params, permitted_params)
    end

    it 'runs the callbacks' do
      expect(order).to receive(:run_callbacks).with(:updating_from_params)
      order.update_from_params( params, permitted_params)
    end

    context "passing a credit card" do
      let(:permitted_params) do
        Spree::PermittedAttributes.checkout_attributes +
          [payments_attributes: Spree::PermittedAttributes.payment_attributes]
      end

      let(:credit_card) { create(:credit_card, user_id: order.user_id) }

      let(:params) do
        ActionController::Parameters.new(
          order: { payments_attributes: [{payment_method_id: 1}] },
          existing_card: credit_card.id,
          cvc_confirm: "737",
          payment_source: {
            "1" => { name: "Luis Braga",
                     number: "4111 1111 1111 1111",
                     expiry: "06 / 2016",
                     verification_value: "737",
                     cc_type: "" }
          }
        )
      end

      before { order.user_id = 3 }

      it "sets confirmation value when its available via :cvc_confirm" do
        allow(Spree::CreditCard).to receive_messages find: credit_card
        expect(credit_card).to receive(:verification_value=)
        order.update_from_params(params, permitted_params)
      end

      it "sets existing card as source for new payment" do
        expect {
          order.update_from_params(params, permitted_params)
        }.to change { Spree::Payment.count }.by(1)

        expect(Spree::Payment.last.source).to eq credit_card
      end

      it "dont let users mess with others users cards" do
        credit_card.update_column :user_id, 5

        expect {
          order.update_from_params(params, permitted_params)
        }.to raise_error
      end
    end

    context 'has params' do
      let(:permitted_params) { [ :good_param ] }
      let(:params) { ActionController::Parameters.new(order: {  bad_param: 'okay' } ) }

      it 'does not let through unpermitted attributes' do
        expect(order).to receive(:update_attributes).with({})
        order.update_from_params(params, permitted_params)
      end

      context 'has allowed params' do
        let(:params) { ActionController::Parameters.new(order: {  good_param: 'okay' } ) }

        it 'accepts permitted attributes' do
          expect(order).to receive(:update_attributes).with({"good_param" => 'okay'})
          order.update_from_params(params, permitted_params)
        end
      end

      context 'callbacks halt' do
        before do
          expect(order).to receive(:update_params_payment_source).and_return false
        end
        it 'does not let through unpermitted attributes' do
          expect(order).not_to receive(:update_attributes).with({})
          order.update_from_params(params, permitted_params)
        end
      end
    end
  end
end
