require 'spec_helper'

describe Spree::Product do
  subject { create(:product_with_variants) }
  let(:variant) { subject.variants.first}

  its(:visible_option_types) { should be_blank }
  its(:product_group)        { should be_kind_of(Spree::ProductGroup) }

  describe "#not_assembly" do
    it "excludes products with assembly definition" do
      create(:assembly_definition, variant: subject.master)

      expect(Spree::Product.all).to eq [subject]
      expect(Spree::Product.all.not_assembly).to be_empty
    end

    it "includes kits without assembly definition" do
      part = create(:variant)
      subject.add_part part

      expect(Spree::Product.all).to match_array [part.product, subject]
      expect(Spree::Product.all.not_assembly).to match_array [part.product, subject]
    end
  end

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

    let!(:variant1) do
      create(:variant, product: r2w, sku: 'part1', in_stock_cache: true)
    end

    let!(:variant2) do
      create(:variant, product: r2w, sku: 'part2', in_stock_cache: true)
    end

    before do
      p = variant1.price_normal_in('USD')
      p.amount = 18.00
      p.save

      p = variant1.price_normal_sale_in('USD')
      p.amount = 14.00
      p.save

      p = variant2.price_normal_in('USD')
      p.amount = 17.99
      p.save

      p = variant2.price_normal_sale_in('USD')
      p.amount = 16.99
      p.save
    end

    context "no variant in sale" do

      it "returns lowest sale price" do
        expect(r2w.lowest_priced_variant("USD", in_sale: true)).to be_nil
      end

      it "returns lowest normal price" do
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
      variant3 = create(:variant, amount: 120.00, currency: "GBP", product: r2w, in_stock_cache: true)
      variant4 = create(:variant, amount: 30.00, currency: "GBP", product: r2w, in_stock_cache: true)
      expect(r2w.lowest_priced_variant("GBP")).to eq(variant4)
    end

    it "with some variants out of stock" do
      variant3 = create(:variant, amount: 1.00, currency: "USD", product: r2w)
      variant4 = create(:variant, amount: 15.00, currency: "USD", product: r2w)
      expect(r2w.lowest_priced_variant("USD")).to eq(variant2)
    end

    it "for kit products with some variants out of stock" do
      kit = create(:base_product, product_type: create(:product_type_kit))

      kit_variant1 = create(:variant, amount: 14.00, currency: "USD", product: kit, sku: 'v1', in_stock_cache: false)
      kit_variant2 = create(:variant, amount: 14.01, currency: "USD", product: kit, sku: 'v2', in_stock_cache: true)
      kit_variant3 = create(:variant, amount: 15.00, currency: "USD", product: kit, sku: 'v3', in_stock_cache: true)

      expect(kit.lowest_priced_variant("USD")).to eq(kit_variant2)
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

  describe "#stock_threshold_for" do
    let(:location) { create(:stock_location) }
    subject(:product) { create(:base_product) }

    it "returns the StockThreshold value" do
      product.master.stock_thresholds.create(stock_location: location, value: 100)
      expect(product.stock_threshold_for(location)).to eq(100)
    end

    it "defaults to 0" do
      expect(product.stock_threshold_for(location)).to eq(0)
    end
  end
end
