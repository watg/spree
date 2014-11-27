require 'spec_helper'

module Spree
  describe StockLocation do
    subject { create(:stock_location_with_items, backorderable_default: true) }
    let(:stock_item) { subject.stock_items.order(:id).first }
    let(:variant) { stock_item.variant }
    let(:supplier) { create(:supplier) }

    it 'creates stock_items for all variants' do
      subject.stock_items.count.should eq Variant.count
    end

    context "#available?" do

      let(:stock_location) { build_stubbed(:stock_location) }

      before do
        subject.active = false
        subject.feed_into = nil
      end

      it "is false if both active is false and feed_into is null" do
        expect(subject.available?).to be_false
      end

      it "is true if active" do
        subject.active = true
        expect(subject.available?).to be_true
      end

      it "is true if feed_into is not null" do
        subject.feed_into = stock_location
        expect(subject.available?).to be_true
      end

    end

    context "handling stock items" do
      let!(:variant) { create(:variant) }

      context "given a variant" do
        subject { StockLocation.create(name: "testing", propagate_all_variants: false) }

        context "set up" do
          it "creates stock item" do
            subject.should_receive(:propagate_variant)
            subject.set_up_stock_item(variant)
          end

          context "stock item exists" do
            let!(:stock_item) { subject.propagate_variant(variant) }

            it "returns existing stock item" do
              subject.set_up_stock_item(variant).should == stock_item
            end
          end
        end

        context "propagate variants" do
          let(:stock_item) { subject.propagate_variant(variant) }

          it "creates a new stock item" do
            expect {
              subject.propagate_variant(variant)
            }.to change{ StockItem.count }.by(1)
          end

          context "with supplier" do
            it "creates a new stock item" do
              stock_item = nil
              expect {
                stock_item = subject.propagate_variant(variant, supplier)
              }.to change{ StockItem.count }.by(1)
              expect(stock_item.supplier).to eq supplier
            end
          end

          context "passes backorderable default config" do
            context "true" do
              before { subject.backorderable_default = true }
              it { stock_item.backorderable.should be_true }
            end

            context "false" do
              before { subject.backorderable_default = false }
              it { stock_item.backorderable.should be_false }
            end
          end
        end

        context "propagate all variants" do
          subject { StockLocation.new(name: "testing") }

          context "true" do
            before { subject.propagate_all_variants = true }

            specify do
              subject.should_receive(:propagate_variant).at_least(:once)
              subject.save!
            end
          end

          context "false" do
            before { subject.propagate_all_variants = false }

            specify do
              subject.should_not_receive(:propagate_variant)
              subject.save!
            end
          end

        end
      end
    end

    context "#stock_item" do

      it 'finds a stock_item for a variant' do
        stock_item = subject.stock_item(variant)
        stock_item.count_on_hand.should eq 10
      end

      it 'finds a stock_item for a variant by id' do
        stock_item = subject.stock_item(variant.id)
        stock_item.variant.should eq variant
      end

      it 'returns nil when stock_item is not found for variant' do
        stock_item = subject.stock_item(100)
        stock_item.should be_nil
      end

      it 'creates a stock_item if not found for a variant' do
        variant = create(:variant)
        variant.stock_items.destroy_all
        variant.save

        stock_item = subject.stock_item_or_create(variant)
        stock_item.variant.should eq variant
      end

      it 'finds a count_on_hand for a variant' do
        subject.count_on_hand(variant).should eq 10
      end

      it 'finds determines if you a variant is backorderable' do
        subject.backorderable?(variant).should be_true
      end

      context "with supplier" do
        let(:supplier_2) { create(:supplier) }

        before do
          stock_item.supplier = supplier
          stock_item.save
        end

        it 'finds a stock_item for a variant and supplier' do
          stock_item = subject.stock_item(variant, supplier)
          stock_item.count_on_hand.should eq 10
        end

        it 'finds a stock_item for variant  and supplier id' do
          stock_item = subject.stock_item(variant, supplier.id)
          stock_item.variant.should eq variant
        end

        it 'returns nil when stock_item is not found for supplier' do
          stock_item = subject.stock_item(variant, 100)
          stock_item.should be_nil
        end

        it 'creates a stock_item if not found for a variant and supplier' do
          variant = create(:variant)
          variant.stock_items.destroy_all
          variant.save

          stock_item = subject.stock_item_or_create(variant, supplier)
          stock_item.variant.should eq variant
          stock_item.supplier.should eq supplier
        end

        # We create 2 x extra stock_items ontop of the existing one that belongs to supplier
        # supplier: nil ( test whether
        context "count_on_hand" do
          before do
            si1 = variant.stock_items.create( stock_location: subject, supplier: nil)
            si1.set_count_on_hand(3)
            si2 = variant.stock_items.create( stock_location: subject, supplier: supplier_2)
            si2.set_count_on_hand(2)
          end

          it 'returns total count inc stock_items without suppliers' do
            subject.count_on_hand(variant).should eq 15
          end

          it 'finds a count_on_hand for a variant and supplier' do
            subject.count_on_hand(variant, supplier).should eq 10
          end
        end


        it 'finds determines if you a variant is backorderable' do
          subject.backorderable?(variant, supplier).should be_true
        end

      end

    end

    it 'restocks a variant with a positive stock movement' do
      originator = double
      supplier = double
      subject.should_receive(:move).with(variant, 5, originator, supplier)
      subject.restock(variant, 5, originator, supplier )
    end

    context "unstock" do
      it 'unstocks a variant with a negative stock movement' do
        originator = double
        supplier = double
        mock_movement = mock_model(Spree::StockMovement, stock_item: stock_item)
        subject.should_receive(:move).with(variant, -5, originator, supplier).and_return(mock_movement)
        subject.unstock(variant, 5, originator, supplier)
      end
    end

    it 'it creates a stock_movement' do
      expect {
        subject.move variant, 5
      }.to change { subject.stock_movements.where(stock_item_id: stock_item).count }.by(1)
    end

    it 'can be deactivated' do
      create(:stock_location, :active => true)
      create(:stock_location, :active => false)
      Spree::StockLocation.active.count.should eq 1
    end

    context 'fill_status' do

      it 'all on_hand with no backordered' do
        items = subject.fill_status(variant, 5)
        items.should eq [5, 0, 0]
      end

      it 'some on_hand with some backordered' do
        items = subject.fill_status(variant, 20)
        items.should eq [10, 10, 0]
      end

      it 'zero on_hand with all backordered' do
        zero_stock_item = mock_model(StockItem,
                                     count_on_hand: 0,
                                     backorderable?: true)

        subject.should_receive(:available_stock_items).with(variant).and_return([zero_stock_item])

        on_hand, backordered, awaiting_feed = subject.fill_status(variant, 20)
        on_hand.should eq 0
        backordered.should eq 20
        awaiting_feed.should eq 0
      end

      context "when partial stock is in a feeder location" do
        let(:feeder_location) { create(:stock_location_with_items, active: false, feed_into: subject) }
        let!(:feeder_stock_item) { feeder_location.stock_items.first }

        before do
          stock_item.send(:count_on_hand=, 5)
          stock_item.save!
          feeder_stock_item.send(:count_on_hand=, 5)
          feeder_stock_item.save!
        end

        it "backorders enough stock" do
          on_hand, backordered, awaiting_feed = subject.fill_status(variant, 20)
          on_hand.should eq 5
          backordered.should eq 10
          awaiting_feed.should eq 5
        end
      end

      context 'when backordering is not allowed' do
        before do
          @stock_item = mock_model(StockItem, backorderable?: false)
          subject.should_receive(:available_stock_items).with(variant).and_return([@stock_item])
        end

        it 'all on_hand' do
          @stock_item.stub(count_on_hand: 10)

          on_hand, backordered, awaiting_feed = subject.fill_status(variant, 5)
          on_hand.should eq 5
          backordered.should eq 0
          awaiting_feed.should eq 0
        end

        it 'some on_hand' do
          @stock_item.stub(count_on_hand: 10)

          on_hand, backordered, awaiting_feed = subject.fill_status(variant, 20)
          on_hand.should eq 10
          backordered.should eq 0
          awaiting_feed.should eq 0
        end

        it 'zero on_hand' do
          @stock_item.stub(count_on_hand: 0)

          on_hand, backordered, awaiting_feed = subject.fill_status(variant, 20)
          on_hand.should eq 0
          backordered.should eq 0
          awaiting_feed.should eq 0
        end
      end

      context "when backordering is not allowed and stock is available from a feeder location" do
        let(:feeder_location) { create(:stock_location_with_items, active: false, feed_into: subject) }
        let!(:feeder_stock_item) { feeder_location.stock_items.first }

        before do
          stock_item.backorderable = false
          stock_item.send(:count_on_hand=, 5)
          stock_item.save!
        end

        it "backorders all stock from the feeder if possible" do
          feeder_stock_item.send(:count_on_hand=, 30)
          feeder_stock_item.backorderable = false
          feeder_stock_item.save!

          on_hand, backordered, awaiting_feed = subject.fill_status(variant, 20)
          on_hand.should eq 5
          backordered.should eq 0
          awaiting_feed.should eq 15
        end

        it "backorders partial stock from the feeder" do
          feeder_stock_item.send(:count_on_hand=, 5)
          feeder_stock_item.backorderable = false
          feeder_stock_item.save!

          on_hand, backordered, awaiting_feed = subject.fill_status(variant, 20)
          on_hand.should eq 5
          backordered.should eq 0
          awaiting_feed.should eq 5
        end

        it "backorders all if feeder stock is backorderable" do
          feeder_stock_item.send(:count_on_hand=, 0)
          feeder_stock_item.backorderable = true
          feeder_stock_item.save!

          on_hand, backordered, awaiting_feed = subject.fill_status(variant, 20)
          on_hand.should eq 5
          backordered.should eq 15
          awaiting_feed.should eq 0
        end
      end

      context "available_stock_items" do

        it "returns the items if they are backorderable" do
          stock_item.set_count_on_hand(0)
          stock_item.update_column(:backorderable, true)
          expect(subject.available_stock_items(variant)).to eq [stock_item]
        end

        it "returns the items if they have count on hand" do
          stock_item.set_count_on_hand(1)
          stock_item.update_column(:backorderable, false)
          expect(subject.available_stock_items(variant)).to eq [stock_item]
        end

        it "does not return items which are not backorderable and have no count_on_hand" do
          stock_item.set_count_on_hand(0)
          stock_item.update_column(:backorderable, false)
          expect(subject.available_stock_items(variant)).to eq []
        end


      end

      context 'without stock_items' do
        subject { create(:stock_location) }
        let(:variant) { create(:base_variant) }

        it 'zero on_hand and backordered', focus: true do
          subject
          variant.stock_items.destroy_all
          items = subject.fill_status(variant, 1)
          items.should eq [0, 0, 0]
        end
      end
    end
  end

  describe "feeder" do
    let(:london) { build(:stock_location, active: true) }
    subject(:stock_location) { build(:stock_location, active: false) }

    it "only be set on inactive locations" do
      stock_location.active = true
      stock_location.feed_into = london
      expect(stock_location).not_to be_valid

      stock_location.active = false
      expect(stock_location).to be_valid
    end

    it "can only feed into active locations" do
      london.active = false
      stock_location.feed_into = london
      expect(stock_location).not_to be_valid

      london.active = true
      expect(stock_location).to be_valid
    end
  end

  describe "available" do
    let(:inactive_locations) { create_list(:stock_location, 2, active: false) }
    let(:active_locations) { create_list(:stock_location, 2, active: true) }
    let(:feeder_locations) { create_list(:stock_location, 2, feed_into: active_locations.first, active: false) }
    let(:available_locations) { active_locations + feeder_locations }

    it "returns active and feeder locations" do
      expect(StockLocation.available).to eq(available_locations)
    end
  end


  describe ".valid_feed_into_locations_for" do
    let!(:inactive_locations) { create_list(:stock_location, 2, active: false) }
    let!(:active_locations) { create_list(:stock_location, 2, active: true) }
    let!(:feeder_locations) { create_list(:stock_location, 2, active: false, feed_into: active_locations.first) }

    it "returns active locations excluding the current location" do
      current_location = create(:stock_location, active: true)
      expect(StockLocation.valid_feed_into_locations_for(current_location)).to eq(active_locations)
    end
  end

  describe ".with_feeders" do
    let!(:location_with_feeder) { create(:stock_location) }
    let!(:feeder_locations) { create_list(:stock_location, 2, active: false, feed_into: location_with_feeder) }
    let!(:location_without_feeder) { create(:stock_location) }

    it "returns all locations with feeders" do
      expect(StockLocation.with_feeders).to match_array([location_with_feeder])
    end
  end
end
