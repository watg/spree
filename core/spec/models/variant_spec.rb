require "spec_helper"

describe Spree::Variant do
  let!(:variant) { create(:variant) }

  context "stock control" do
    let!(:variant_in_stock) { create(:variant_with_stock_items, product_id: variant.product.id) }

    it "checks stock level" do
      allow_any_instance_of(Spree::StockItem).to receive_messages(backorderable: false)
      expect(variant_in_stock.in_stock?).to be true
      expect(variant.in_stock?).to be false
    end
  end

  describe "#total_on_hand" do
    it "is infinite if track_inventory_levels is false" do
      Spree::Config[:track_inventory_levels] = false
      expect(build(:variant).total_on_hand).to eql(Float::INFINITY)
    end

    it "matches quantifier total_on_hand" do
      variant = build(:variant)
      expect(variant.total_on_hand).to eq(Spree::Stock::Quantifier.new(variant).total_on_hand)
    end
  end

  describe "total_awaiting_feed" do
    it "uses the value from inventory unit" do
      variant = build(:variant)
      allow(Spree::InventoryUnit).to receive(:total_awaiting_feed_for)
        .with(variant).and_return(3)
      expect(variant.total_awaiting_feed).to eq(3)
    end
  end

  describe "#backordered" do
    it "calls the correct method chain" do
      non_pending = double
      inventory_units = double
      expect(non_pending).to receive(:backordered)
      expect(inventory_units).to receive(:non_pending).and_return(non_pending)
      expect(variant).to receive(:inventory_units).and_return(inventory_units)
      variant.backordered
    end
  end

  describe "awaiting_feed" do
    it "calls the correct method chain" do
      non_pending = double
      inventory_units = double
      expect(non_pending).to receive(:awaiting_feed)
      expect(inventory_units).to receive(:non_pending).and_return(non_pending)
      expect(variant).to receive(:inventory_units).and_return(inventory_units)
      variant.awaiting_feed
    end
  end

  describe "#images_for" do
    let(:variant) { create(:variant) }
    let!(:variant_images) { create_list(:image, 1, viewable: variant, position: 2) }
    let(:target) { create(:target) }

    context "with a VariantTarget" do
      let(:variant_target_images) do
        create_list(:image, 1, viewable: variant, target: target, position: 3)
      end
      let!(:images) { variant_images + variant_target_images }

      it "returns all images linked to the VariantTarget and Variant" do
        expect(variant.images_for(target)).to eq(images)
      end
    end

    context "with no VariantTarget" do
      it "returns all images linked to the Variant" do
        expect(variant.images_for(target)).to eq(variant_images)
      end
    end

    context "with a position" do
      let(:variant_target_images) do
        create_list(:image, 1, viewable: variant, target: target, position: 1)
      end
      let!(:images) { variant_target_images + variant_images }

      it "returns all images linked to the VariantTarget and Variant" do
        expect(variant.images_for(target)).to eq(images)
      end
    end
  end

  describe "touching" do
    before { Timecop.freeze }
    after { Timecop.return }

    context "product" do
      it "is updated" do
        variant.product.update_column(:updated_at, 1.day.ago)
        variant.touch
        expect(variant.product.reload.updated_at).to be_within(1.seconds).of(Time.now)
      end
    end
  end

  describe "#add_to_all_product_parts" do
    context "after creating a new variant" do
      let(:variant) { build(:base_variant) }

      before do
        Delayed::Worker.delay_jobs = false
      end

      after { Delayed::Worker.delay_jobs = true }

      it "is automatically added to all product parts variants" do
        mock = double(Spree::Jobs::AddVariantToProductParts)

        expect(Spree::Jobs::AddVariantToProductParts).to receive(:new)
          .once.with(variant).and_return(mock)
        expect(mock).to receive(:perform).once

        variant.save
      end
    end
  end

  describe "#stock_threshold_for" do
    let(:location) { create(:stock_location) }
    subject(:variant) { create(:variant) }

    it "returns the StockThreshold value" do
      variant.stock_thresholds.create(stock_location: location, value: 100)
      expect(variant.stock_threshold_for(location)).to eq(100)
    end

    it "defaults to 0" do
      expect(variant.stock_threshold_for(location)).to eq(0)
    end

    it "works for unsaved variants" do
      variant = build(:variant)
      variant.stock_thresholds.build(stock_location: location, value: 50)
      expect(variant.stock_threshold_for(location)).to eq(50)
    end
  end

  describe ".with_stock_threshold_for" do
    let(:london) { create(:stock_location) }
    let(:bray) { create(:stock_location) }

    let(:variant1) { create(:variant) }
    let(:variant2) { create(:variant) }
    let(:variant3) { create(:variant) }
    let(:variant4) { create(:variant) }

    it "returns variants with non-zero stock thresholds for a location" do
      variant1.stock_thresholds.create(stock_location: london, value: 1)
      variant2.stock_thresholds.create(stock_location: bray, value: 1)
      variant3.stock_thresholds.create(stock_location: london, value: 0)
      variant4.stock_thresholds.create(stock_location: london, value: 100)

      expect(described_class.with_stock_threshold_for(london)).to match_array([variant1, variant4])
    end
  end
end
