require 'spec_helper'
require 'benchmark'

describe Spree::Shipment, :type => :model do
  let(:order) { mock_model Spree::Order, backordered?: false,
                                         canceled?: false,
                                         can_ship?: true,
                                         currency: 'USD',
                                         number: 'S12345',
                                         products: [],
                                         paid?: false,
                                         touch: true }
  let(:shipping_method) { create(:shipping_method, name: "UPS") }
  let(:shipment) do
    shipment = Spree::Shipment.new(state: 'pending')
    allow(shipment).to receive_messages order: order
    allow(shipment).to receive_messages shipping_method: shipping_method
    shipment.save
    shipment
  end

  let(:variant) { mock_model(Spree::Variant) }
  let(:line_item) { mock_model(Spree::LineItem, variant: variant) }

  # Regression test for #4063
  context "number generation" do
    before do
      allow(order).to receive :update!
    end

    it "generates a number containing a letter + 11 numbers" do
      shipment.save
      expect(shipment.number[0]).to eq("H")
      expect(/\d{11}/.match(shipment.number)).not_to be_nil
      expect(shipment.number.length).to eq(12)
    end
  end

  it 'is backordered if one if its inventory_units is backordered' do
    allow(shipment).to receive_messages(inventory_units: [
      mock_model(Spree::InventoryUnit, backordered?: false),
      mock_model(Spree::InventoryUnit, backordered?: true)
    ])
    expect(shipment).to be_backordered
  end

  it 'is awaiting_feed if one if its inventory_units is awaiting_feed' do
    allow(shipment).to receive_messages(inventory_units: [
      mock_model(Spree::InventoryUnit, awaiting_feed?: false),
      mock_model(Spree::InventoryUnit, awaiting_feed?: true)
    ])
    expect(shipment).to be_awaiting_feed
  end


  context '#determine_state' do
    it 'returns canceled if order is canceled?' do
      allow(order).to receive_messages canceled?: true
      expect(shipment.determine_state(order)).to eq 'canceled'
    end

    it 'returns pending unless order.can_ship?' do
      allow(order).to receive_messages can_ship?: false
      expect(shipment.determine_state(order)).to eq 'pending'
    end

    it 'returns pending if backordered' do
      allow(shipment).to receive_messages inventory_units: [mock_model(Spree::InventoryUnit, backordered?: true)]
      expect(shipment.determine_state(order)).to eq 'pending'
    end

    it 'returns shipped when already shipped' do
      allow(shipment).to receive_messages state: 'shipped'
      expect(shipment.determine_state(order)).to eq 'shipped'
    end

    it 'returns pending when unpaid' do
      expect(shipment.determine_state(order)).to eq 'pending'
    end

    it 'returns ready when paid' do
      allow(order).to receive_messages paid?: true
      expect(shipment.determine_state(order)).to eq 'ready'
    end

    it "returns awaiting feed" do
      allow(order).to receive_messages(can_ship?: true)
      allow(shipment).to receive_messages(
        inventory_units: [mock_model(Spree::InventoryUnit, backordered?: false, awaiting_feed?: true)]
      )
      expect(shipment.determine_state(order)).to eq 'awaiting_feed'
    end

    it 'returns ready when Config.auto_capture_on_dispatch' do
      Spree::Config.auto_capture_on_dispatch = true
      expect(shipment.determine_state(order)).to eq 'ready'
    end
  end

  describe 'express' do
    context 'contains express shipping method' do
      let(:express) { create(:shipping_method, express: true) }
      before        { subject.shipping_methods = [express] }
      it            { is_expected.to be_express }
    end

    context 'does not contain express shipping method' do
      let(:express) { create(:shipping_method, express: false) }
      before        { subject.shipping_methods = [express] }
      it            { is_expected.to_not be_express }
    end
  end

  context "display_amount" do
    it "retuns a Spree::Money" do
      allow(shipment).to receive(:cost) { 21.22 }
      expect(shipment.display_amount).to eq(Spree::Money.new(21.22))
    end
  end

  context "display_final_price" do
    it "retuns a Spree::Money" do
      allow(shipment).to receive(:final_price) { 21.22 }
      expect(shipment.display_final_price).to eq(Spree::Money.new(21.22))
    end
  end

  context "display_item_cost" do
    it "retuns a Spree::Money" do
      allow(shipment).to receive(:item_cost) { 21.22 }
      expect(shipment.display_item_cost).to eq(Spree::Money.new(21.22))
    end
  end

  it "#item_cost" do
    shipment = create(:shipment, order: create(:order_with_totals))
    expect(shipment.item_cost).to eql(10.0)
  end

  it "#promo_total" do
    shipment = build(:shipment_light)
    shipment.selected_shipping_rate.promo_total = -1
    expect(shipment.promo_total).to eq(-1)
  end

  it "#discounted_cost" do
    shipment = build(:shipment_light)
    shipment.selected_shipping_rate.cost = 10
    shipment.selected_shipping_rate.promo_total = -1
    expect(shipment.discounted_cost).to eq(9)
  end

  it "#tax_total with included taxes" do
    shipment = build(:shipment_light)
    expect(shipment.tax_total).to eq(0)
    shipment.selected_shipping_rate.included_tax_total = 10
    expect(shipment.tax_total).to eq(10)
  end

  it "#tax_total with additional taxes" do
    shipment = build(:shipment_light)
    expect(shipment.tax_total).to eq(0)
    shipment.selected_shipping_rate.additional_tax_total = 10
    expect(shipment.tax_total).to eq(10)
  end

  it "#final_price" do
    shipment = build(:shipment_light)
    shipment.selected_shipping_rate.cost = 10
    shipment.selected_shipping_rate.adjustment_total = -2
    shipment.selected_shipping_rate.included_tax_total = 1
    expect(shipment.final_price).to eq(8)
  end

  context "manifest" do
    let(:order) { Spree::Order.create }
    let(:variant) { create(:variant) }
    let!(:line_item) { order.contents.add variant }
    let!(:shipment) { order.create_proposed_shipments.first }

    it "returns variant expected" do
      expect(shipment.manifest.first.variant).to eq variant
      expect(shipment.manifest.first.inventory_units).to eq shipment.inventory_units
    end

    context "variant was removed" do
      before { variant.destroy }

      it "still returns variant expected" do
        expect(shipment.manifest.first.variant).to eq variant
      end
    end
  end

  context 'shipping_rates' do
    let(:shipment) { create(:shipment) }
    let(:shipping_method1) { create(:shipping_method) }
    let(:shipping_method2) { create(:shipping_method) }
    let(:shipping_rates) { [
      Spree::ShippingRate.new(shipping_method: shipping_method1, cost: 10.00, selected: true),
      Spree::ShippingRate.new(shipping_method: shipping_method2, cost: 20.00)
    ] }

    it 'returns shipping_method from selected shipping_rate' do
      shipment.shipping_rates.delete_all
      shipment.shipping_rates.create shipping_method: shipping_method1, cost: 10.00, selected: true
      expect(shipment.shipping_method).to eq shipping_method1
    end

    context 'refresh_rates' do
      let(:mock_estimator) { double('estimator', shipping_rates: shipping_rates) }
      before { allow(shipment).to receive(:can_get_rates?){ true } }

      it 'should request new rates, and maintain shipping_method selection' do
        expect(Spree::Stock::Estimator).to receive(:new).with(shipment.order).and_return(mock_estimator)
        allow(shipment).to receive_messages(shipping_method: shipping_method2)
        expect(shipment.refresh_rates).to eq(shipping_rates)
        expect(shipment.reload.selected_shipping_rate.shipping_method_id).to eq(shipping_method2.id)
      end

      it 'should handle no shipping_method selection' do
        expect(Spree::Stock::Estimator).to receive(:new).with(shipment.order).and_return(mock_estimator)
        allow(shipment).to receive_messages(shipping_method: nil)
        expect(shipment.refresh_rates).to eq(shipping_rates)
        expect(shipment.reload.selected_shipping_rate).not_to be_nil
      end

      it 'should not refresh if shipment is shipped' do
        expect(Spree::Stock::Estimator).not_to receive(:new)
        shipment.shipping_rates.delete_all
        allow(shipment).to receive_messages(shipped?: true)
        expect(shipment.refresh_rates).to eq([])
      end

      it "can't get rates without a shipping address" do
        shipment.order(ship_address: nil)
        expect(shipment.refresh_rates).to eq([])
      end

      context 'to_package' do
        let(:inventory_units) do
          [build(:inventory_unit, line_item: line_item, variant: variant, state: 'on_hand'),
           build(:inventory_unit, line_item: line_item, variant: variant, state: 'backordered')]
        end

        before do
          allow(shipment).to receive(:inventory_units) { inventory_units }
          allow(inventory_units).to receive_message_chain(:includes, :joins).and_return inventory_units
        end

        it 'should use symbols for states when adding contents to package' do
          package = shipment.to_package
          expect(package.on_hand.count).to eq 1
          expect(package.backordered.count).to eq 1
        end
      end
    end
  end

  context "#update!" do
    before do
      # custom change
      allow(shipment).to receive(:check_for_only_digital_and_ship)
    end

    shared_examples_for "immutable once shipped" do
      it "should remain in shipped state once shipped" do
        shipment.state = 'shipped'
        expect(shipment).to receive(:update_columns).with(state: 'shipped', updated_at: kind_of(Time))
        shipment.update!(order)
      end
    end

    shared_examples_for "pending if backordered" do
      it "should have a state of pending if backordered" do
        allow(shipment).to receive_messages(inventory_units: [mock_model(Spree::InventoryUnit, backordered?: true)])
        expect(shipment).to receive(:update_columns).with(state: 'pending', updated_at: kind_of(Time))
        shipment.update!(order)
      end
    end

    context "when order cannot ship" do
      before { allow(order).to receive_messages can_ship?: false }
      it "should result in a 'pending' state" do
        expect(shipment).to receive(:update_columns).with(state: 'pending', updated_at: kind_of(Time))
        shipment.update!(order)
      end
    end

    context "when order is paid" do
      before { allow(order).to receive_messages paid?: true }
      it "should result in a 'ready' state" do
        expect(shipment).to receive(:update_columns).with(state: 'ready', updated_at: kind_of(Time))
        shipment.update!(order)
      end
      it_should_behave_like 'immutable once shipped'
      it_should_behave_like 'pending if backordered'
    end

    context "when order has balance due" do
      before { allow(order).to receive_messages paid?: false }
      it "should result in a 'pending' state" do
        shipment.state = 'ready'
        expect(shipment).to receive(:update_columns).with(state: 'pending', updated_at: kind_of(Time))
        shipment.update!(order)
      end
      it_should_behave_like 'immutable once shipped'
      it_should_behave_like 'pending if backordered'
    end

    context "when order has a credit owed" do
      before { allow(order).to receive_messages payment_state: 'credit_owed', paid?: true }
      it "should result in a 'ready' state" do
        shipment.state = 'pending'
        expect(shipment).to receive(:update_columns).with(state: 'ready', updated_at: kind_of(Time))
        shipment.update!(order)
      end
      it_should_behave_like 'immutable once shipped'
      it_should_behave_like 'pending if backordered'
    end

    context "when shipment state changes to shipped" do
      before do
        allow_any_instance_of(Spree::ShipmentHandler).to receive(:send_shipped_email)
        allow_any_instance_of(Spree::ShipmentHandler).to receive(:update_order_shipment_state)
      end

      it "should call after_ship" do
        shipment.state = 'pending'
        expect(shipment).to receive :after_ship
        allow(shipment).to receive_messages determine_state: 'shipped'
        expect(shipment).to receive(:update_columns).with(state: 'shipped', updated_at: kind_of(Time))
        shipment.update!(order)
      end

      context 'customer feedback email' do
        let(:survey) { double(delay: Shipping::CustomerFeedbackMailer.new(order)) }
        let(:mailer) { double }

        before do
          allow(shipment).to receive_messages determine_state: 'shipped'
          allow(Shipping::CustomerFeedbackMailer).to receive(:new).with(order).and_return(survey)
          allow(Spree::ShipmentMailer).to receive(:survey_email).with(order).and_return(mailer)
          Timecop.freeze
        end

        it 'dispatches email in 10 days' do
          expect(survey).to receive(:delay).with({:run_at => 10.days.from_now})
          expect(mailer).to receive(:deliver)
          shipment.state = 'pending'
          shipment.update!(order)
        end
      end

      context 'knitting experience email' do
        let(:mailer) { double }

        before do
          shipment.state = 'pending'
          allow(shipment).to receive_messages determine_state: 'shipped'
          allow(Shipping::KnittingExperienceMailer).to receive(:new).and_return(mailer)
          Timecop.freeze
        end

        it 'dispatches email' do
          expect(mailer).to receive(:delay).with({:run_at => 1.month.from_now}).and_return(mailer)
          expect(mailer).to receive(:perform)
          shipment.update!(order)
        end
      end

      context "when using the default shipment handler" do
        it "should call the 'perform' method" do
          shipment.state = 'pending'
          allow(shipment).to receive_messages determine_state: 'shipped'
          expect_any_instance_of(Spree::ShipmentHandler).to receive(:perform)
          shipment.update!(order)
        end
      end

      context "when using a custom shipment handler" do
        before do
          Spree::ShipmentHandler::UPS = Class.new {
            def initialize(shipment) true end
            def perform() true end
          }
        end

        it "should call the custom handler's 'perform' method" do
          shipment.state = 'pending'
          allow(shipment).to receive_messages determine_state: 'shipped'
          expect_any_instance_of(Spree::ShipmentHandler::UPS).to receive(:perform)
          shipment.update!(order)
        end

        after do
          Spree::ShipmentHandler.send(:remove_const, :UPS)
        end
      end

    end
  end

  context "when order is completed" do
    after { Spree::Config.set track_inventory_levels: true }

    before do
      allow(order).to receive_messages completed?: true
      allow(order).to receive_messages canceled?: false
    end

    context "with inventory tracking" do
      before { Spree::Config.set track_inventory_levels: true }

      it "should validate with inventory" do
        shipment.inventory_units = [create(:inventory_unit)]
        expect(shipment.valid?).to be true
      end
    end

    context "without inventory tracking" do
      before { Spree::Config.set track_inventory_levels: false }

      it "should validate with no inventory" do
        expect(shipment.valid?).to be true
      end
    end
  end



  context "when order is completed" do
    after { Spree::Config.set track_inventory_levels: true }

    before do
      allow(order).to receive_messages completed?: true
      allow(order).to receive_messages canceled?: false
    end

    context "with inventory tracking" do
      before { Spree::Config.set track_inventory_levels: true }

      it "should validate with inventory" do
        shipment.inventory_units = [create(:inventory_unit)]
        expect(shipment.valid?).to be true
      end
    end

    context "without inventory tracking" do
      before { Spree::Config.set track_inventory_levels: false }

      it "should validate with no inventory" do
        expect(shipment.valid?).to be true
      end
    end
  end

  context "#cancel" do
    it 'cancels the shipment' do
      allow(shipment.order).to receive(:update!)

      shipment.state = 'pending'
      expect(shipment).to receive(:after_cancel)
      shipment.cancel!
      expect(shipment.state).to eq 'canceled'
    end

    it 'restocks the items' do
      supplier = double
      inventory_units = [mock_model(Spree::InventoryUnit, state: "on_hand", line_item: line_item, variant: variant, supplier: supplier)]
      allow(shipment).to receive(:inventory_units).and_return inventory_units
      stock_allocator = double('stock_allocator')
      expect(stock_allocator).to receive(:restock).with(variant, inventory_units)
      expect(Spree::Stock::Allocator).to receive(:new).with(shipment).and_return(stock_allocator)
      shipment.after_cancel
    end

    context "with backordered inventory units" do
      let(:order) { create(:order) }
      let(:variant) { create(:variant) }
      let(:other_order) { create(:order) }

      before do
        order.contents.add variant
        order.create_proposed_shipments

        other_order.contents.add variant
        other_order.create_proposed_shipments
      end

      it "doesn't fill backorders when restocking inventory units" do
        shipment = order.shipments.first
        expect(shipment.inventory_units.count).to eq 1
        expect(shipment.inventory_units.first).to be_backordered

        other_shipment = other_order.shipments.first
        expect(other_shipment.inventory_units.count).to eq 1
        expect(other_shipment.inventory_units.first).to be_backordered

        expect {
          shipment.cancel!
        }.not_to change { other_shipment.inventory_units.first.state }
      end
    end
  end

  context "#resume" do
    it 'will determine new state based on order' do
      allow(shipment.order).to receive(:update!)
      allow(shipment).to receive(:check_for_only_digital_and_ship)

      shipment.state = 'canceled'
      expect(shipment).to receive(:determine_state).and_return(:ready)
      expect(shipment).to receive(:after_resume)
      shipment.resume!
      expect(shipment.state).to eq 'ready'
    end

    context "when the shipment is pending" do
      before do
        shipment.state = 'pending'
        shipment.save!
      end

      it "leaves the state in pending" do
        expect(shipment).not_to receive(:after_resume)
        shipment.resume!
      end

      it "does not call the after_resume callback" do
        shipment.resume!
        expect(shipment).to be_pending
      end
    end

    context "when the shipment is ready" do
      before do
        allow(shipment).to receive(:check_for_only_digital_and_ship)
        shipment.state = 'ready'
        shipment.save!
      end

      it "leaves the state in ready" do
        expect(shipment).not_to receive(:after_resume)
        expect(shipment.reload).to be_ready

        shipment.resume!
      end
    end

    it 'unstocks them items' do
      supplier = double
      inventory_units = [mock_model(Spree::InventoryUnit, line_item: line_item, variant: variant, supplier: supplier)]

      allow(shipment).to receive(:inventory_units).and_return inventory_units

      stock_allocator = double('stock_allocator')
      expect(stock_allocator).to receive(:unstock).with(variant, inventory_units)
      expect(Spree::Stock::Allocator).to receive(:new).with(shipment).and_return(stock_allocator)
      shipment.after_resume
    end

    it 'will determine new state based on order' do
      allow(shipment.order).to receive(:update!)

      shipment.state = 'canceled'
      expect(shipment).to receive(:determine_state).twice.and_return('ready')
      expect(shipment).to receive(:after_resume)
      shipment.resume!
      # Shipment is pending because order is already paid
      expect(shipment.state).to eq 'pending'
    end
  end

  context "#ship" do
    context "when the shipment is canceled" do
      # Note this has been heavily refactored to work with the way we unstock and restock
      let(:shipment_with_inventory_units) { create(:shipment, order: create(:order_with_line_items), state: 'canceled') }
      let(:inventory_units) { shipment_with_inventory_units.inventory_units }
      let(:subject) { shipment_with_inventory_units.ship! }
      let(:variant) {shipment_with_inventory_units.inventory_units.first.variant }
      let(:stock_location) { shipment_with_inventory_units.stock_location }
      let!(:stock_item) {create(:stock_item, variant: variant, stock_location: stock_location) }
      let!(:count_on_hand) { stock_item.count_on_hand }
      before do
        allow(order).to receive(:update!)
        allow(shipment_with_inventory_units).to receive_messages(require_inventory: false, update_order: true)
      end

      it 'unstocks them items' do
        allow_any_instance_of(Spree::ShipmentHandler).to receive(:update_order_shipment_state)
        allow_any_instance_of(Spree::ShipmentHandler).to receive(:send_shipped_email)
        # expect(stock_location).to receive(:unstock)
        subject
        expect(stock_item.reload.count_on_hand).to eq count_on_hand - inventory_units.size
      end
    end

    ['ready', 'canceled'].each do |state|
      context "from #{state}" do
        before do
          allow(order).to receive(:update!)
          allow(shipment).to receive_messages(require_inventory: false, update_order: true, state: state)
        end

        it "should update shipped_at timestamp" do
          allow_any_instance_of(Spree::ShipmentHandler).to receive(:update_order_shipment_state)
          allow_any_instance_of(Spree::ShipmentHandler).to receive(:send_shipped_email)

          shipment.ship!
          expect(shipment.shipped_at).not_to be_nil
          # Ensure value is persisted
          shipment.reload
          expect(shipment.shipped_at).not_to be_nil
        end

        it "should send a shipment email" do
          mail_message = double 'Mail::Message'
          shipment_id = nil
          expect(Spree::ShipmentMailer).to receive(:shipped_email) { |*args|
            shipment_id = args[0]
            mail_message
          }
          expect(mail_message).to receive :deliver
          allow_any_instance_of(Spree::ShipmentHandler).to receive(:update_order_shipment_state)

          shipment.ship!
          expect(shipment_id).to eq(shipment.id)
        end

      end
    end
  end

  context "#ready" do
    context 'with Config.auto_capture_on_dispatch == false' do
      # Regression test for #2040
      it "cannot ready a shipment for an order if the order is unpaid" do
        allow(order).to receive_messages(paid?: false)
        assert !shipment.can_ready?
      end
    end

    context 'with Config.auto_capture_on_dispatch == true' do
      before do
        Spree::Config[:auto_capture_on_dispatch] = true
        @order = create :completed_order_with_pending_payment
        @shipment = @order.shipments.first
        # the shipping rates will get refreshed as part of the 
        # completed_order_with_pending_payment, create, as it creates
        # a payment which calls update_order that causes a brand new 
        # set of shipping rates to be created
        @shipment.selected_shipping_rate.cost = @order.ship_total
      end

      it "shipments ready for an order if the order is unpaid" do
        expect(@shipment.ready?).to be true
      end

      it "tells the order to process payment in #after_ship" do
        expect(@shipment).to receive(:process_order_payments)
        @shipment.ship!
      end

      context "order has pending payments" do
        let(:payment) do
          payment = @order.payments.first
          payment.update_attribute :state, 'pending'
          payment
        end

        it "can fully capture an authorized payment" do
          payment.update_attribute(:amount, @order.total)
          expect(payment.amount).to eq payment.uncaptured_amount
          @shipment.ship!
          expect(payment.reload.uncaptured_amount.to_f).to eq 0
        end

        it "can partially capture an authorized payment" do
          payment.update_attribute(:amount, @order.total + 50)
          expect(payment.amount).to eq payment.uncaptured_amount
          @shipment.ship!
          expect(payment.reload.uncaptured_amount).to eq 50
        end
      end
    end
  end

  context "changes shipping rate via general update" do
    let(:order) do
      Spree::Order.create(
        payment_total: 100, payment_state: 'paid', total: 100, item_total: 100
      )
    end

    let(:shipment) { Spree::Shipment.create order_id: order.id }

    let(:shipping_rate) do
      Spree::ShippingRate.create shipment_id: shipment.id, cost: 10
    end

    before do
    end

    it "updates everything around order shipment total and state" do
      expect(shipment).to receive(:update_shipping_rate_adjustments).once
      shipment.update_attributes_and_order selected_shipping_rate_id: shipping_rate.id
      expect(shipment.state).to eq 'pending'
      expect(shipment.order.total.to_f).to eq 110
      expect(shipment.order.payment_state).to eq 'balance_due'
    end

  end

  describe "update_shipping_rate_adjustments" do
    it "updates the adjustments on shipping rates" do
      shipping_rate = stub_model(Spree::ShippingRate)
      shipment = stub_model(Spree::Shipment, :order => order, :shipping_rates => [shipping_rate])
      shipments = [shipment]
      allow(order).to receive_messages :shipments => shipments
      updater = double("Updater")
      expect(updater).to receive(:update).once
      expect(::Shipping::AdjustmentsUpdater).to receive(:new).with([shipping_rate]).
        and_return(updater)
      shipment.update_shipping_rate_adjustments
    end
  end

  context "after_save" do
    context "line item changes" do
      before do
        shipment.cost = shipment.cost + 10
      end
    end

    context "line item does not change" do
      it "does not trigger adjustment total recalculation" do
        expect(shipment).not_to receive(:recalculate_adjustments)
        shipment.save
      end
    end
  end

  context "currency" do
    it "returns the order currency" do
      expect(shipment.currency).to eq(order.currency)
    end
  end

  context "#tracking_url" do
    it "uses shipping method to determine url" do
      expect(shipping_method).to receive(:build_tracking_url).with('1Z12345').and_return(:some_url)
      shipment.tracking = '1Z12345'

      expect(shipment.tracking_url).to eq(:some_url)
    end
  end

  context "set up new inventory units" do
    # let(:line_item) { double(
    let(:line_item_part) { mock_model(Spree::LineItemPart, line_item: line_item, variant: variant) }
    let(:variant) { double("Variant", id: 9) }

    let(:inventory_units) { double }
    let(:supplier) { create(:supplier) }

    let(:params) do
      { variant_id: variant.id, state: 'on_hand', order_id: order.id, line_item_id: line_item.id, supplier_id: supplier.id, line_item_part_id: line_item_part.id }
    end

    before { allow(shipment).to receive_messages inventory_units: inventory_units }

    it "associates variant and order" do
      expect(inventory_units).to receive(:create).with(params)
      unit = shipment.set_up_inventory('on_hand', variant, order, line_item, supplier, line_item_part)
    end
  end

  # Regression test for #3349
  context "#destroy" do
    it "destroys linked shipping_rates" do
      reflection = Spree::Shipment.reflect_on_association(:shipping_rates)
      expect(reflection.options[:dependent]).to be(:delete_all)
    end
  end


  # Regression test for #4072 (kinda)
  # The need for this was discovered in the research for #4702
  context "state changes" do
    before do
      # Must be stubbed so transition can succeed
      allow(order).to receive_messages :paid? => true
      allow(order).to receive_messages physical_line_items: [double('Non-digital item')]
      allow(shipment).to receive(:check_for_only_digital_and_ship)
    end

    it "are logged to the database" do
      expect(shipment.state_changes).to be_empty
      expect(shipment.ready!).to be true
      expect(shipment.state_changes.count).to eq(1)
      state_change = shipment.state_changes.first
      expect(state_change.previous_state).to eq('pending')
      expect(state_change.next_state).to eq('ready')
    end
  end

  context "shipment contains only digital items will automatically ship" do
    before do
      allow(order).to receive_messages :paid? => true
      allow(shipment).to receive :after_ship
      allow(order).to receive_messages physical_line_items: []
      allow(order).to receive_messages line_items: [line_item]
    end

    it "ultising state machine call backs" do
      shipment.state = "pending"
      shipment.ready!
      expect(shipment.state).to eq "shipped"
    end

    it "ignoring state machine callbacks (spreehack) with #update!" do
      shipment.state = "pending"
      shipment.update!(order)
      expect(shipment.state).to eq "shipped"
    end
  end

  context "shipment contains non digital items does not automatically ship" do
    before do
      allow(order).to receive_messages physical_line_items: [double('Non-digital item')]
      allow(order).to receive_messages line_items: [line_item]
      allow(order).to receive_messages :paid? => true
      allow(shipment).to receive(:check_for_only_digital_and_ship)
    end

    it "ultising state machine call backs" do
      shipment.state = "pending"
      shipment.ready!
      expect(shipment.state).to eq "ready"
    end

    it "ignoring state machine callbacks (spreehack) with #update!" do
      shipment.state = "pending"
      shipment.update!(order)
      expect(shipment.state).to eq "ready"
    end
  end

  describe "#waiting_to_ship" do
    it "is true if state is pending" do
      shipment = described_class.new(state: "pending")
      expect(shipment).to be_waiting_to_ship
    end

    it "is true if state is ready" do
      shipment = described_class.new(state: "ready")
      expect(shipment).to be_waiting_to_ship
    end

    it "is true if state is awaiting_feed" do
      shipment = described_class.new(state: "awaiting_feed")
      allow(shipment).to receive(:awaiting_feed?).and_return(true)
      expect(shipment).to be_waiting_to_ship
    end

    it "is false for all other states" do
      all_states = described_class.state_machine.states.map(&:name)
      other_states = all_states - %w(ready pending awaiting_feed)
      other_states.each do |state|
        shipment = described_class.new(state: state)
        expect(shipment).not_to be_waiting_to_ship
      end
    end
  end
end
