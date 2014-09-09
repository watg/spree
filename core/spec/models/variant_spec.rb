require 'spec_helper'

describe Spree::Variant do
  let!(:variant) { create(:variant) }

  context "stock control" do
    let!(:variant_in_stock) { create(:variant_with_stock_items, product_id: variant.product.id) }

    it "checks stock level" do
      Spree::StockItem.any_instance.stub(backorderable: false)
      expect(variant_in_stock.in_stock?).to be_true
      expect(variant.in_stock?).to be_false
    end

  end

  describe "with tags" do
    let(:tags) { 2.times.map { FactoryGirl.create(:tag) } }

    before :each do
      subject.tags = tags
    end

    its(:tag_names) { should eq(tags.map(&:value)) }
  end


  describe '#total_on_hand' do
    it 'should be infinite if track_inventory_levels is false' do
      Spree::Config[:track_inventory_levels] = false
      build(:variant).total_on_hand.should eql(Float::INFINITY)
    end

    it 'should match quantifier total_on_hand' do
      variant = build(:variant)
      expect(variant.total_on_hand).to eq(Spree::Stock::Quantifier.new(variant).total_on_hand)
    end
  end

  describe "#images_for" do
    let(:variant) { create(:variant) }
    let!(:variant_images) { create_list(:image, 1, viewable: variant, position: 2) }
    let(:target) { create(:target) }

    context "with a VariantTarget" do
      let(:variant_target_images) { create_list(:image, 1, viewable: variant, target: target, position: 3) }
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
      let(:variant_target_images) { create_list(:image, 1, viewable: variant, target: target, position: 1) }
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
        variant.product.reload.updated_at.should be_within(1.seconds).of(Time.now)
      end
    end

    context "index_page_items" do
      let!(:index_page_item) { create(:index_page_item, variant: variant, updated_at: 1.month.ago) }

      it "is updated" do
        variant.reload # reload to pick up the index_page_item has_many
        variant.touch
        expect(index_page_item.reload.updated_at).to be_within(1.seconds).of(Time.now)
      end
    end
  end

  describe "#add_to_all_assembly_definitions" do
    context 'after creating a new variant' do
      let(:variant) { build(:base_variant) }

      before do
        Delayed::Worker.delay_jobs = false
      end

      after { Delayed::Worker.delay_jobs = true }

      it 'is automatically added to all assembly definition variants' do
        mock = double(Spree::Jobs::AddVariantToAssemblyPart)

        expect(Spree::Jobs::AddVariantToAssemblyPart).to receive(:new).once.with(variant).and_return(mock)
        expect(mock).to receive(:perform).once

        variant.save
      end

    end
  end

end
