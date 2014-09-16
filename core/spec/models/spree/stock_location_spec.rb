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
      before { Timecop.freeze }
      after { Timecop.return }

      it 'unstocks a variant with a negative stock movement' do
        originator = double
        supplier = double
        mock_movement = mock_model(Spree::StockMovement, stock_item: stock_item)
        stock_item.should_receive(:update_columns).with({last_unstocked_at:  Time.now})
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

    context 'first_on_hand' do

      before do
        stock_item.backorderable = false
        stock_item.last_unstocked_at = Time.now.yesterday
        stock_item.save
      end

      it "will return the first available on_hand stock item" do
        item = subject.first_on_hand(variant)
        expect(item).to eq stock_item
      end

      context "no on_hand in stock" do

        before do
          stock_item.set_count_on_hand(0)
        end

        it "will return the first available on_hand stock item" do
          item = subject.first_on_hand(variant)
          expect(item).to eq stock_item
        end

      end

    end

    context 'fill_status' do
      it 'all on_hand with no backordered' do
        on_hand = subject.fill_status(variant, 5)
        on_hand.should eq [Spree::StockLocation::FillStatusItem.new( nil, 5 )]
      end

      it 'some on_hand with some backordered' do
        on_hand = subject.fill_status(variant, 20)
        on_hand.should eq [Spree::StockLocation::FillStatusItem.new( nil, 10 )]
      end

      it 'zero on_hand with all backordered' do
        subject.should_receive(:stock_items_on_hand).with(variant).and_return([])

        on_hand = subject.fill_status(variant, 20)
        on_hand.should eq []
      end

      context 'with supplier' do
        let(:supplier_2) { create(:supplier) }
        let(:si_1) {variant.stock_items.create( stock_location: subject, supplier: supplier, backorderable: true, last_unstocked_at: Time.now)}
        let(:si_2) {variant.stock_items.create( stock_location: subject, supplier: supplier_2, backorderable: false, last_unstocked_at: Time.now.yesterday)}

        before do
          stock_item.backorderable = false
          stock_item.last_unstocked_at = Time.now.yesterday
          stock_item.save
          stock_item.set_count_on_hand(1)
          si_1.set_count_on_hand(3)
          si_2.set_count_on_hand(2)
        end

        context "all on_hand with no backordered" do

          it "tries to satisfy with the same supplier" do
            on_hand = subject.fill_status(variant, 3)
            on_hand.should eq [
              Spree::StockLocation::FillStatusItem.new( supplier, 3 ),
            ]
          end

          it "tries to satisfy with the all suppliers if needed" do
            on_hand = subject.fill_status(variant, 6)
            on_hand.should eq [
              Spree::StockLocation::FillStatusItem.new( supplier, 3 ),
              Spree::StockLocation::FillStatusItem.new( supplier_2, 2 ),
              Spree::StockLocation::FillStatusItem.new( nil, 1 ),
            ]
          end

          it "tries to satisfy in last unstocked_at order" do
            on_hand = subject.fill_status(variant, 2)
            on_hand.should eq [
              Spree::StockLocation::FillStatusItem.new( supplier_2, 2 )
            ]
          end

        end

        context "some on_hand with some backordered" do

          it "tries to satisfy with the all suppliers if needed" do
            on_hand = subject.fill_status(variant, 10)
            on_hand.should eq [
              Spree::StockLocation::FillStatusItem.new( supplier, 3 ),
              Spree::StockLocation::FillStatusItem.new( supplier_2, 2 ),
              Spree::StockLocation::FillStatusItem.new( nil, 1 ),
            ]
          end

        end

        context "zero on_hand with all backordered" do
          before do
            stock_item.set_count_on_hand(0)
            si_1.set_count_on_hand(0)
            si_2.set_count_on_hand(0)
          end

          it "tries to satisfy with the all suppliers if needed" do
            on_hand = subject.fill_status(variant, 10)
            on_hand.should eq []
          end

        end

      end

      context 'without stock_items' do
        subject { create(:stock_location) }
        let(:variant) { create(:base_variant) }

        it 'zero on_hand and backordered', focus: true do
          subject
          variant.stock_items.destroy_all
          on_hand = subject.fill_status(variant, 1)
          on_hand.should eq []
        end
      end
    end
  end
end
