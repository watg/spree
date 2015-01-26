require 'spec_helper'

describe Spree::StockItem, :type => :model do
  let(:stock_location) { create(:stock_location_with_items) }
  let!(:stock_item) { stock_location.stock_items.first }

  subject { stock_location.stock_items.order(:id).first }

  it 'maintains the count on hand for a variant' do
    expect(subject.count_on_hand).to eq 10
  end

  it "can return the stock item's variant's name" do
    expect(subject.variant_name).to eq(subject.variant.name)
  end

  describe "#from_available_locations" do
    let!(:stock_location_2) { create :stock_location }
    let!(:stock_location_3) { create :stock_location, active: false }
    let!(:stock_location_4) { create :stock_location, feed_into: stock_location_2, active: false }

    before do
      stock_location_2.stock_items.where(variant_id: stock_item.variant).update_all(count_on_hand: 5, backorderable: false)
      stock_location_3.stock_items.where(variant_id: stock_item.variant).update_all(count_on_hand: 5, backorderable: false)
      stock_location_4.stock_items.where(variant_id: stock_item.variant).update_all(count_on_hand: 5, backorderable: false)
    end

    it "return stock items from only avaiable locations" do
      stock_items = described_class.from_available_locations.
        where(variant: stock_item.variant)

      expect(stock_items.size).to eq 3

      stock_locations = stock_items.map(&:stock_location)

      expected_stock_locations = [
        stock_location,
        stock_location_2,
        stock_location_4,
      ]

      expect(stock_locations).to match_array expected_stock_locations
    end
  end

  context "available to be included in shipment" do
    context "has stock" do
      it { expect(subject).to be_available }
    end

    context "backorderable" do
      before { subject.backorderable = true }
      it { expect(subject).to be_available }
    end

    context "no stock and not backorderable" do
      before do
        subject.backorderable = false
        allow(subject).to receive_messages(count_on_hand: 0)
      end

      it { expect(subject).not_to be_available }
    end
  end

  describe 'reduce_count_on_hand_to_zero' do
    context 'when count_on_hand > 0' do
      before(:each) do
        subject.update_column('count_on_hand', 4)
         subject.reduce_count_on_hand_to_zero
       end

       it { expect(subject.count_on_hand).to eq(0) }
     end

     context 'when count_on_hand > 0' do
       before(:each) do
         subject.update_column('count_on_hand', -4)
         @count_on_hand = subject.count_on_hand
         subject.reduce_count_on_hand_to_zero
       end

       it { expect(subject.count_on_hand).to eq(@count_on_hand) }
     end
  end

  context "adjust count_on_hand" do
    let!(:current_on_hand) { subject.count_on_hand }

    it 'is updated pessimistically' do
      copy = Spree::StockItem.find(subject.id)

      subject.adjust_count_on_hand(5)
      expect(subject.count_on_hand).to eq(current_on_hand + 5)

      expect(copy.count_on_hand).to eq(current_on_hand)
      copy.adjust_count_on_hand(5)
      expect(copy.count_on_hand).to eq(current_on_hand + 10)
    end

    context "check_variant_stock" do

      it "creates a job after save" do
        mock_object = double('stock_check_job', perform: true)
        expect(Spree::StockCheckJob).to receive(:new).with(subject.variant).and_return(mock_object)
        expect(::Delayed::Job).to receive(:enqueue).with(mock_object, queue: 'stock_check', priority: 10)
        subject.send(:conditional_variant_touch)
      end
    end

    context "item out of stock" do
      let(:inventory_unit) { double('InventoryUnit', fill_backorder: true, backordered?: true) }
      let(:inventory_unit_2) { double('InventoryUnit2', fill_backorder: true, backordered?: true) }

      before do
        allow(subject).to receive_messages(:backordered_inventory_units => [inventory_unit, inventory_unit_2])
        subject.update_column(:count_on_hand, -2)
      end

      # Regression test for #3755
      it "processes existing backorders, even with negative stock" do
        #inventory_unit.should_receive(:fill_backorder)
        #inventory_unit_2.should_not_receive(:fill_backorder)
        expect(subject).to receive(:waiting_units_processor).and_return double.as_null_object
        expect(subject).to receive(:process_waiting_inventory_units).with(1).and_call_original
        subject.adjust_count_on_hand(1)
        expect(subject.count_on_hand).to eq(-1)
      end

      # Test for #3755
      it "does not process backorders when stock is adjusted negatively" do
        #inventory_unit.should_not_receive(:fill_backorder)
        #inventory_unit_2.should_not_receive(:fill_backorder)
        expect(subject).to_not receive(:waiting_units_processor)
        expect(subject).to receive(:process_waiting_inventory_units).with(-1).and_call_original
        subject.adjust_count_on_hand(-1)
        expect(subject.count_on_hand).to eq(-3)
      end

# The new WaitingUnitsProcessor takes care of the below
#      context "adds new items" do
#        let(:backordered_inventory_units) { [inventory_unit, inventory_unit_2] }
#        let(:waiting_inventory_units) { backordered_inventory_units }
#
#        before do
#          subject.stub(:waiting_inventory_units => waiting_inventory_units)
#        end
#
#        it "fills existing backorders" do
#          #inventory_unit.should_receive(:fill_backorder)
#          #inventory_unit_2.should_receive(:fill_backorder)
#          expect(subject).to receive(:process_waiting_inventory_units)
#          subject.adjust_count_on_hand(3)
#          subject.count_on_hand.should == 1
#        end
#
#        context "with inventory units awaiting feed" do
#          let(:inventory_unit_3) {
#            double('InventoryUnit3',
#              :fill_awaiting_feed => true,
#              :backordered?       => false,
#              :awaiting_feed?     => true,
#              :supplier_id=       => true)
#          }
#
#          let(:inventory_unit_4) {
#            double('InventoryUnit4',
#              :fill_awaiting_feed => true,
#              :backordered?       => false,
#              :awaiting_feed?     => true,
#              :supplier_id=       => true)
#          }
#
#          let(:waiting_inventory_units) { backordered_inventory_units + [inventory_unit_3, inventory_unit_4] }
#
#          let(:order_1) { build(:order) }
#          let(:order_2) { build(:order) }
#
#          before do
#            allow(order_1).to receive(:update!)
#            allow(order_2).to receive(:update!)
#            allow(inventory_unit_3).to receive(:order).and_return(order_1)
#            allow(inventory_unit_4).to receive(:order).and_return(order_2)
#          end
#
#          it "fills those inventory units" do
#            expect(inventory_unit).to receive(:fill_backorder)
#            expect(inventory_unit_2).to receive(:fill_backorder)
#            expect(inventory_unit_3).to receive(:fill_awaiting_feed)
#            expect(inventory_unit_4).to receive(:fill_awaiting_feed)
#
#            subject.adjust_count_on_hand(4)
#          end
#
#          it "updates the orders" do
#            subject.adjust_count_on_hand(4)
#
#            expect(order_1).to have_received(:update!)
#            expect(order_2).to have_received(:update!)
#          end
#
#          describe "supplier_id" do
#            let(:waiting_inventory_unit) { create(:inventory_unit, state: "awaiting_feed", supplier_id: nil) }
#            subject(:stock_item) { create(:stock_item) }
#
#            it "gets set on the inventory unit" do
#              allow(stock_item).to receive(:waiting_inventory_units).and_return([waiting_inventory_unit])
#              stock_item.adjust_count_on_hand(3)
#              expect(waiting_inventory_unit.reload.supplier_id).to eq(stock_item.supplier_id)
#            end
#          end
#
#          it "sets the correct count on hand" do
#            subject.adjust_count_on_hand(3)
#            expect(subject.count_on_hand).to eq(0)
#          end
#        end
#      end
    end
  end

  context "set count_on_hand" do
    let!(:current_on_hand) { subject.count_on_hand }

    it 'is updated pessimistically' do
      copy = Spree::StockItem.find(subject.id)

      subject.set_count_on_hand(5)
      expect(subject.count_on_hand).to eq(5)

      expect(copy.count_on_hand).to eq(current_on_hand)
      copy.set_count_on_hand(10)
      expect(copy.count_on_hand).to eq(current_on_hand)
    end

    context "item out of stock (by two items)" do
      let(:inventory_unit) { double('InventoryUnit', backordered?: true) }
      let(:inventory_unit_2) { double('InventoryUnit2', backordered?: true) }

      before { subject.set_count_on_hand(-2) }

      it "does process waiting units if count on hand is decreased" do
        expect(subject).to_not receive(:waiting_units_processor)
        expect(subject).to receive(:process_waiting_inventory_units).with(-1).and_call_original
        subject.set_count_on_hand(-3)
      end

      it "does process waiting units if count on hand is increased" do
        subject.set_count_on_hand(-2)
        expect(subject).to receive(:waiting_units_processor).and_return double.as_null_object
        expect(subject).to receive(:process_waiting_inventory_units).with(1).and_call_original
        subject.set_count_on_hand(-1)
      end

#      context "adds new items" do
#        before { subject.stub(:waiting_inventory_units => [inventory_unit, inventory_unit_2]) }
#
#        xit "fills existing backorders" do
#          #inventory_unit.should_receive(:fill_backorder)
#          #inventory_unit_2.should_receive(:fill_backorder)
#
#          subject.set_count_on_hand(1)
#          subject.count_on_hand.should == 1
#        end
#      end
    end
  end

  describe "#waiting_units_processor" do

    it "instantiates WaitingUnitsProcessor correctly" do
      expect(Spree::Stock::WaitingUnitsProcessor).to receive(:new).with(subject)
      subject.send(:waiting_units_processor)
    end

  end

  context "with stock movements" do
    before { Spree::StockMovement.create(stock_item: subject, quantity: 1) }

    it "doesnt raise ReadOnlyRecord error" do
      expect { subject.destroy }.not_to raise_error
    end
  end

  context "destroyed" do
    before { subject.destroy }

    it "recreates stock item just fine" do
      expect {
        stock_location.stock_items.create!(variant: subject.variant)
      }.not_to raise_error
    end

    it "doesnt allow recreating more than one stock item at once" do
      stock_location.stock_items.create!(variant: subject.variant)

      expect {
        stock_location.stock_items.create!(variant: subject.variant)
      }.to raise_error
    end
  end

  describe "#after_save" do
    before do
      subject.variant.update_column(:updated_at, 1.day.ago)
      Delayed::Worker.delay_jobs = false
    end

    after { Delayed::Worker.delay_jobs = true }

    context "clear_total_on_hand_cache" do
      it "gets called" do
        expect(subject).to receive(:conditional_clear_total_on_hand_cache)
        subject.save
      end
    end

    context "conditional_clear_backorderable_cache" do
      it "gets called" do
        expect(subject).to receive(:clear_backorderable_cache)
        subject.save
      end
    end

    context "binary_inventory_cache is set to false (default)" do
      context "in_stock? changes" do
        it "touches its variant" do
          expect do
            subject.adjust_count_on_hand(subject.count_on_hand * -1)
          end.to change { subject.variant.reload.updated_at }
        end
      end

      context "in_stock? does not change" do
        it "touches its variant" do
          expect do
            subject.adjust_count_on_hand((subject.count_on_hand * -1) + 1)
          end.to change { subject.variant.reload.updated_at }
        end
      end
    end

    context "binary_inventory_cache is set to true" do
      before { Spree::Config.binary_inventory_cache = true }
      context "in_stock? changes" do
        it "touches its variant" do
          expect do
            subject.adjust_count_on_hand(subject.count_on_hand * -1)
          end.to change { subject.variant.reload.updated_at }
        end
      end

      context "in_stock? does not change" do
        it "does not touch its variant" do
          expect do
            subject.adjust_count_on_hand((subject.count_on_hand * -1) + 1)
          end.not_to change { subject.variant.reload.updated_at }
        end
      end

      context "when a new stock location is added" do
        it "touches its variant" do
          expect do
            create(:stock_location)
          end.to change { subject.variant.reload.updated_at }
        end
      end
    end
  end

  describe "#after_destroy" do
    before do
      Delayed::Worker.delay_jobs = false
    end

    after { Delayed::Worker.delay_jobs = true }

    context "clear_total_on_hand_cache" do
      it "gets called" do
        expect(subject).to receive(:clear_total_on_hand_cache)
        subject.destroy
      end
    end
  end


  describe "stock_quantifier" do

    it "returns an instance of the stock Quantifier" do
      expect(Spree::Stock::Quantifier).to receive(:new).with(subject.variant)
      subject.send(:stock_quantifier)
    end

  end

  describe "clear_total_on_hand_cache" do

    let(:variant) { build_stubbed(:base_variant)}
    let(:stock_quantifier) { Spree::Stock::Quantifier.new(variant)}

    before { allow(subject).to receive(:stock_quantifier).and_return(stock_quantifier) }

    it "is calls the stock quantifier" do
      expect(stock_quantifier).to receive(:clear_total_on_hand_cache)
      subject.send(:clear_total_on_hand_cache)
    end

  end

  describe "conditional_clear_total_on_hand_cache" do

    let(:variant) { build_stubbed(:base_variant)}
    let(:stock_quantifier) { Spree::Stock::Quantifier.new(variant)}

    before { allow(subject).to receive(:stock_quantifier).and_return(stock_quantifier) }

    it "is called if count_on_hand_changed? is true" do
      allow(subject).to receive(:count_on_hand_changed?).and_return(true)
      expect(stock_quantifier).to receive(:clear_total_on_hand_cache)
      subject.send(:conditional_clear_total_on_hand_cache)
    end

    it "is not called if count_on_hand_changed? is false" do
      allow(subject).to receive(:count_on_hand_changed?).and_return(false)
      expect(stock_quantifier).to_not receive(:clear_total_on_hand_cache)
      subject.send(:conditional_clear_total_on_hand_cache)
    end

    it "is called if variant_id_changed? is true" do
      allow(subject).to receive(:variant_id_changed?).and_return(true)
      expect(stock_quantifier).to receive(:clear_total_on_hand_cache)
      subject.send(:conditional_clear_total_on_hand_cache)
    end

    it "is not called if variant_id_changed? is false" do
      allow(subject).to receive(:variant_id_changed?).and_return(false)
      expect(stock_quantifier).to_not receive(:clear_total_on_hand_cache)
      subject.send(:conditional_clear_total_on_hand_cache)
    end

  end


  describe "clear_backorderable_cache" do

    let(:variant) { build_stubbed(:base_variant)}
    let(:stock_quantifier) { Spree::Stock::Quantifier.new(variant)}

    before { allow(subject).to receive(:stock_quantifier).and_return(stock_quantifier) }

    it "is called if backorderable_changed? is true" do
      allow(subject).to receive(:backorderable_changed?).and_return(true)
      expect(stock_quantifier).to receive(:clear_backorderable_cache)
      subject.send(:clear_backorderable_cache)
    end

    it "is not called if backorderable_changed? is false" do
      allow(subject).to receive(:backorderable_changed?).and_return(false)
      expect(stock_quantifier).to_not receive(:clear_backorderable_cache)
      subject.send(:clear_backorderable_cache)
    end

    it "is called if variant_id_changed? is true" do
      allow(subject).to receive(:variant_id_changed?).and_return(true)
      expect(stock_quantifier).to receive(:clear_total_on_hand_cache)
      subject.send(:clear_total_on_hand_cache)
    end

    it "is not called if variant_id_changed? is false" do
      allow(subject).to receive(:variant_id_changed?).and_return(false)
      expect(stock_quantifier).to_not receive(:clear_backorderable_cache)
      subject.send(:clear_backorderable_cache)
    end

  end

  describe "stock_changed?" do
    it "is true when count on hand changes from positive to 0" do
      subject.send(:count_on_hand=,0)
      expect(subject.send(:stock_changed?)).to be true
    end

    it "is false when it changes but not to 0" do
      subject.send(:count_on_hand=,1123)
      expect(subject.send(:stock_changed?)).to be false
    end

    it "is true if the variant_id changes from nil" do
      subject.variant_id = nil
      expect(subject.send(:stock_changed?)).to be true
    end

  end

  describe "#after_touch" do
    it "touches its variant" do
      expect do
        subject.touch
      end.to change { subject.variant.updated_at }
    end
  end

  describe "#number_of_shipments_pending" do
    let(:variant) { subject.variant }

    let(:order) do
      order = create(:order)
      order.state = 'complete'
      order.completed_at = Time.now
      order.tap(&:save!)
    end

    let(:shipment) do
      shipment = Spree::Shipment.new
      shipment.stock_location = stock_location
      shipment.shipping_methods << create(:shipping_method)
      shipment.order = order
      shipment.state = 'ready'
      # We don't care about this in this test
      shipment.stub(:ensure_correct_adjustment)
      shipment.tap(&:save!)
    end

    let!(:unit) do
      unit = shipment.inventory_units.build
      #unit.state = 'backordered'
      unit.variant_id = stock_item.variant.id
      unit.order_id = order.id
      unit.pending = false
      unit.tap(&:save!)
    end

    it "takes into account pending false" do
      expect(stock_item.number_of_shipments_pending).to eq 1
    end

    it "takes into account pending true" do
      unit.pending = true
      unit.save
      expect(stock_item.number_of_shipments_pending).to eq 0
    end

    it "is influenced by order states (cancel)" do
      order.update_column(:state, 'cancel')
      expect(stock_item.reload.number_of_shipments_pending).to eq 0
    end

    it "is influenced by order states (resumed)" do
      shipment.update_column(:state, 'ready')
      order.update_column(:state, 'resumed')
      expect(stock_item.reload.number_of_shipments_pending).to eq 1
    end

    it "is influenced by shipments states" do
      shipment.update_column(:state, 'shipped')
      expect(stock_item.reload.number_of_shipments_pending).to eq 0
    end

    context "supplier" do
      let(:supplier) { create(:supplier) }

      before do
        unit.supplier = supplier
        unit.save
      end

      it "take no supplier" do
        stock_item.supplier = nil
        expect(stock_item.number_of_shipments_pending).to eq 0
      end

      it "takes into account a supplier" do
        stock_item.supplier = supplier
        expect(stock_item.number_of_shipments_pending).to eq 1
      end

    end

    context "stock_location" do
      let(:another_stock_location) { create(:stock_location) }

      before do
        stock_item.stock_location = another_stock_location
      end

      it "takes  account a stock_locations" do
        expect(stock_item.number_of_shipments_pending).to eq 0
      end
    end
  end # #number_of_shipments_pending


  # Regression test for #4651
  context "variant" do
    it "can be found even if the variant is deleted" do
      subject.variant.destroy
      expect(subject.reload.variant).not_to be_nil
    end
  end

  describe 'validations' do
    describe 'count_on_hand' do
      shared_examples_for 'valid count_on_hand' do
        before(:each) do
          subject.save
        end

        it 'has :no errors_on' do
           expect(subject.errors_on(:count_on_hand).size).to eq(0)
        end
      end

      shared_examples_for 'not valid count_on_hand' do
        before(:each) do
          subject.save
        end

        it 'has 1 error_on' do
          expect(subject.error_on(:count_on_hand).size).to eq(1)
        end
        it { expect(subject.errors[:count_on_hand]).to include 'must be greater than or equal to 0' }
      end

      context 'when count_on_hand not changed' do
        context 'when not backorderable' do
          before(:each) do
            subject.backorderable = false
          end
          it_should_behave_like 'valid count_on_hand'
        end

        context 'when backorderable' do
          before(:each) do
            subject.backorderable = true
          end
          it_should_behave_like 'valid count_on_hand'
        end
      end

      context 'when count_on_hand changed' do
        context 'when backorderable' do
          before(:each) do
            subject.backorderable = true
          end
          context 'when both count_on_hand and count_on_hand_was are positive' do
            context 'when count_on_hand is greater than count_on_hand_was' do
              before(:each) do
                subject.update_column(:count_on_hand, 3)
                subject.send(:count_on_hand=, subject.count_on_hand + 3)
              end
              it_should_behave_like 'valid count_on_hand'
            end

            context 'when count_on_hand is smaller than count_on_hand_was' do
              before(:each) do
                subject.update_column(:count_on_hand, 3)
                subject.send(:count_on_hand=, subject.count_on_hand - 2)
              end

              it_should_behave_like 'valid count_on_hand'
            end
          end

          context 'when both count_on_hand and count_on_hand_was are negative' do
            context 'when count_on_hand is greater than count_on_hand_was' do
              before(:each) do
                subject.update_column(:count_on_hand, -3)
                subject.send(:count_on_hand=, subject.count_on_hand + 2)
              end
              it_should_behave_like 'valid count_on_hand'
            end

            context 'when count_on_hand is smaller than count_on_hand_was' do
              before(:each) do
                subject.update_column(:count_on_hand, 3)
                subject.send(:count_on_hand=, subject.count_on_hand - 3)
              end

              it_should_behave_like 'valid count_on_hand'
            end
          end

          context 'when both count_on_hand is positive and count_on_hand_was is negative' do
            context 'when count_on_hand is greater than count_on_hand_was' do
              before(:each) do
                subject.update_column(:count_on_hand, -3)
                subject.send(:count_on_hand=, subject.count_on_hand + 6)
              end
              it_should_behave_like 'valid count_on_hand'
            end
          end

          context 'when both count_on_hand is negative and count_on_hand_was is positive' do
            context 'when count_on_hand is greater than count_on_hand_was' do
              before(:each) do
                subject.update_column(:count_on_hand, 3)
                subject.send(:count_on_hand=, subject.count_on_hand - 6)
              end
              it_should_behave_like 'valid count_on_hand'
            end
          end
        end

        context 'when not backorderable' do
          before(:each) do
            subject.backorderable = false
          end

          context 'when both count_on_hand and count_on_hand_was are positive' do
            context 'when count_on_hand is greater than count_on_hand_was' do
              before(:each) do
                subject.update_column(:count_on_hand, 3)
                subject.send(:count_on_hand=, subject.count_on_hand + 3)
              end
              it_should_behave_like 'valid count_on_hand'
            end

            context 'when count_on_hand is smaller than count_on_hand_was' do
              before(:each) do
                subject.update_column(:count_on_hand, 3)
                subject.send(:count_on_hand=, subject.count_on_hand - 2)
              end

              it_should_behave_like 'valid count_on_hand'
            end
          end

          context 'when both count_on_hand and count_on_hand_was are negative' do
            context 'when count_on_hand is greater than count_on_hand_was' do
              before(:each) do
                subject.update_column(:count_on_hand, -3)
                subject.send(:count_on_hand=, subject.count_on_hand + 2)
              end
              it_should_behave_like 'valid count_on_hand'
            end

            context 'when count_on_hand is smaller than count_on_hand_was' do
              before(:each) do
                subject.update_column(:count_on_hand, -3)
                subject.send(:count_on_hand=, subject.count_on_hand - 3)
              end

              it_should_behave_like 'not valid count_on_hand'
            end
          end

          context 'when both count_on_hand is positive and count_on_hand_was is negative' do
            context 'when count_on_hand is greater than count_on_hand_was' do
              before(:each) do
                subject.update_column(:count_on_hand, -3)
                subject.send(:count_on_hand=, subject.count_on_hand + 6)
              end
              it_should_behave_like 'valid count_on_hand'
            end
          end

          context 'when both count_on_hand is negative and count_on_hand_was is positive' do
            context 'when count_on_hand is greater than count_on_hand_was' do
              before(:each) do
                subject.update_column(:count_on_hand, 3)
                subject.send(:count_on_hand=, subject.count_on_hand - 6)
              end
              it_should_behave_like 'not valid count_on_hand'
            end
          end
        end
      end
    end
  end
end
