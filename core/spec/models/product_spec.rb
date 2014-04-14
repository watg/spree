require 'spec_helper'

describe Spree::Product do
  subject { create(:product_with_variants) }
  let(:variant) { subject.variants.first}

  its(:visible_option_types) { should be_blank }
  its(:product_group)        { should be_kind_of(Spree::ProductGroup) }
  its(:gang_member)          { should be_kind_of(Spree::GangMember) }

  context "stock control" do
    let!(:variant_in_stock) { create(:variant_with_stock_items, product_id: variant.product.id) }

    it "returns first variant in stock in the scope of product" do
      expect(variant.product.next_variant_in_stock).to eq(variant_in_stock)
    end

    it "returns first variant in stock in the scope of product" do
      variant_in_stock.is_master = true
      variant_in_stock.save
      expect(variant.product.next_variant_in_stock).to be_nil
    end
  end

  it "has got product type" do
    types = [:kit, :product, :virtual_product, :pattern, :parcel, :accessory, :made_by_the_gang, :gift_card]
    Spree::Product::types.should =~ types
  end

  its(:first_variant_or_master) { should eql(variant) }
  context "product has no variant" do
    subject { create(:base_product) }
    its(:first_variant_or_master) { should be_is_master }
  end

  describe "#all_variants_or_master" do
    subject { create(:base_product) }

    context "with single master variant" do
      it "#all_variants_or_master" do
        expect(subject.all_variants_or_master).to be_kind_of(ActiveRecord::Relation)
        expect(subject.all_variants_or_master).to eq([subject.master])
      end

    end

    context "with multiple variants" do
      let(:variants) { 2.times.map { create(:variant, :product => subject) } }
      its(:all_variants_or_master) { should eq(variants) }
    end
  end

  context "#lowest_priced_variant in stock" do
    let(:r2w) { create(:base_product) }
    let!(:variant1) {
      v = create(:variant, price: 18.00, currency: "USD", product: r2w, sku: 'part1', in_stock_cache: true)
      create(:price, amount: 14.00, currency: "USD", sale: true, variant: v)
      v }
    let!(:variant2) {
      v = create(:variant, price: 17.99, currency: "USD", product: r2w, sku: 'part2', in_stock_cache: true)
      create(:price, amount: 16.99, currency: "USD", sale: true, variant: v)
      v }

    context "no variant in sale" do

      it "returns lowest sale price" do
        expect(r2w.lowest_priced_variant("USD", in_sale: true)).to be_nil
      end

      it "returns lowest nornal price" do
        expect(r2w.lowest_priced_variant("USD")).to eq(variant2)
      end

    end

    context "variants in sale" do
      before {  variant1.update_attributes(in_sale: true) }

      it "returns lowest sale price" do
        expect(r2w.lowest_priced_variant("USD", in_sale: true)).to eq(variant1)
      end

      it "returns lowest nornal price" do
        expect(r2w.lowest_priced_variant("USD")).to eq(variant2)
      end

    end

    it "scoped by currency" do
      variant3 = create(:variant, price: 120.00, currency: "GBP", product: r2w, in_stock_cache: true)
      variant4 = create(:variant, price: 30.00, currency: "GBP", product: r2w, in_stock_cache: true)
      d {r2w}
      expect(r2w.lowest_priced_variant("GBP")).to eq(variant4)
    end

    it "with some variants out of stock" do
      variant3 = create(:variant, price: 1.00, currency: "USD", product: r2w)
      variant4 = create(:variant, price: 15.00, currency: "USD", product: r2w)
      expect(r2w.lowest_priced_variant("USD")).to eq(variant2)
    end

    it "for kit products with some variants out of stock" do
      kit = create(:base_product, product_type: :kit)

      kit_variant1 = create(:variant, price: 14.00, currency: "USD", product: kit, sku: 'v1', in_stock_cache: false)
      kit_variant2 = create(:variant, price: 14.01, currency: "USD", product: kit, sku: 'v2', in_stock_cache: true)
      kit_variant3 = create(:variant, price: 15.00, currency: "USD", product: kit, sku: 'v3', in_stock_cache: true)

      expect(kit.lowest_priced_variant("USD")).to eq(kit_variant2)
    end
  end

  describe "#images_for" do
    let!(:variant_images) { create_list(:image, 1, viewable: variant) }
    let(:target1) { create(:target) }
    let(:target2) { create(:target) }

    context "with a VariantTarget" do
      let!(:variant_target1) { create(:variant_target, variant: variant, target: target1) }
      let!(:variant_target2) { create(:variant_target, variant: variant, target: target2) }
      let(:variant_target_image1) { create_list(:image, 1, viewable: variant_target1) }
      let(:variant_target_image2) { create_list(:image, 1, viewable: variant_target2) }
      let!(:images) { variant_target_image1 + variant_images }

      it "returns all images linked to the VariantTarget and Variant" do
        expect(subject.images_for(target1)).to eq(images)
      end
    end

    context "with no VariantTarget" do
      it "returns all images linked to the Variant" do
        expect(subject.images_for(target1)).to eq(variant_images)
      end
    end
  end

  describe "#description_for" do
    subject { create(:base_product, description: "Just a very basic description") }
    let(:target1) { create(:target) }
    let(:target2) { create(:target) }

    context "with a Product Target" do
      let!(:product_target1) { create(:product_target, product: subject, target: target1, description: "Splendid and amazing") }
      let!(:product_target2) { create(:product_target, product: subject, target: target2, description: "Smashingly superb!") }

      it "returns targeted description when one is present" do
        expect(subject.description_for(target1)).to eq "Splendid and amazing"
        expect(subject.description_for(target2)).to eq "Smashingly superb!"
      end
    end

    context "with no Product Target" do
      it "returns main product description" do
        expect(subject.description_for(nil)).to eq "Just a very basic description"
        expect(subject.description_for(target1)).to eq "Just a very basic description"
      end
    end
  end
end
