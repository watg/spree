# encoding: utf-8
require 'spec_helper'

describe Spree::VariantOptions, type: :model do
  let(:currency) { 'USD' }
  let(:product) { build_stubbed(:base_product) }
  let(:variants) { [] }
  let(:context) { { currency: currency, target: target}}

  subject { described_class.new(variants, currency) }

   describe '#option_values_in_stock' do

    before do
      allow_any_instance_of(Spree::StockItem).to receive_messages(backorderable: false)
    end
    context "for made by the gang" do

      let!(:variant_out_stock) { create(:variant, product: product, label: 'women out of stock') }
      let!(:variant_in_stock1)  { create(:variant_with_stock_items, product: product, label: 'women') }
      let(:variants) { [ variant_out_stock, variant_in_stock1 ] }

      it "returns the correct option values" do
        expect(subject.option_values_in_stock).to match_array(variant_in_stock1.option_values)
      end

    end

    context "for kit" do
      let(:product) { create(:product, product_type: create(:product_type_kit)) }

      let!(:kit_variant1) { create(:variant, product: product, in_stock_cache: false) }
      let!(:kit_variant2) { create(:variant, product: product, in_stock_cache: true) }
      let!(:kit_variant3) { create(:variant, product: product, in_stock_cache: true) }

      let(:variants) { [ kit_variant1, kit_variant2, kit_variant3 ] }

      it "returns the correct option values" do
        option_values = kit_variant2.option_values + kit_variant3.option_values
        expect(subject.option_values_in_stock).to match_array(option_values)
      end
    end
  end

  context "multiples types and values" do

    let!(:size)     { create(:option_type, name: 'size', presentation: 'Size', position: 1 )}
    let!(:big)      { create(:option_value, name: 'big', presentation: 'Big', option_type: size, position: 0) }
    let!(:small)    { create(:option_value, name: 'small', presentation: 'Small', option_type: size, position: 1) }

    let!(:colour)   { create(:option_type, name: 'colour', presentation: 'Colour', position: 2 )}
    let!(:pink)     { create(:option_value, name: 'pink', presentation: 'Pink', option_type: colour, position: 0) }
    let!(:blue)     { create(:option_value, name: 'blue', presentation: 'Blue', option_type: colour, position: 1) }

    let!(:language) { create(:option_type, name: 'language', presentation: 'Langauge', position: 3 )}
    let!(:french)   { create(:option_value, name: 'french', presentation: 'French', option_type: language, position: 0) }
    let!(:english)   { create(:option_value, name: 'english', presentation: 'English', option_type: language, position: 1) }


    let!(:variant_in_stock1)  { create(:variant_with_stock_items, product: product, option_values: [pink,small], amount: 19.99 ) }
    let!(:variant_in_stock2)  { create(:variant_with_stock_items, product: product, option_values: [pink,big], amount: 19.99 ) }
    let!(:variant_in_stock3)  { create(:variant_with_stock_items, product: product, option_values: [blue,small], amount: 19.99 ) }
    let!(:variant_in_stock4)  { create(:variant_with_stock_items, product: product, option_values: [blue,big], amount: 19.99 ) }
    let!(:variant_out_stock) { create(:variant, product: product, option_values: [english], amount: 19.99) }

    let(:variants) { [variant_in_stock1, variant_in_stock2, variant_in_stock3, variant_in_stock4, variant_out_stock] }

    before do
      allow_any_instance_of(Spree::StockItem).to receive_messages(backorderable: false)
    end

    describe "#grouped_option_values_in_stock" do

      it "should return untargetted and instock items" do
        grouped_option_values_in_stock = subject.grouped_option_values_in_stock
        expect(grouped_option_values_in_stock[size]).to eq([big,small])
        expect(grouped_option_values_in_stock[colour]).to eq([pink,blue])
      end

    end

    describe "#variant_option_values" do

      it "should return variant_option_values" do
        variant_option_values = subject.variant_option_values
        expect(variant_option_values[variant_in_stock1.number]).to eq [["size", "small"], ["colour", "pink"]]
        expect(variant_option_values[variant_in_stock2.number]).to eq [["size", "big"],   ["colour", "pink"]]
        expect(variant_option_values[variant_in_stock3.number]).to eq [["size", "small"], ["colour", "blue"]]
        expect(variant_option_values[variant_in_stock4.number]).to eq [["size", "big"], ["colour", "blue"]]
        expect(variant_option_values[variant_out_stock.number]).to be_nil
      end

    end

    describe "#tree" do

      context "target and in_stock" do
        it "should return targeted variant_options_tree_for that are in stock " do
          tree = subject.tree
          expect(tree["size"]["small"]["colour"]["pink"]["variant"]["in_stock"]).to be true
          expect(tree["size"]["small"]["colour"]["blue"]["variant"]["in_stock"]).to be true
          expect(tree["size"]["big"]["colour"]["pink"]["variant"]["in_stock"]).to be true
          expect(tree["size"]["big"]["colour"]["blue"]["variant"]["in_stock"]).to be true
        end

      end

      context "option_type positions" do

        before do
          size.update_column(:position, 2)
          colour.update_column(:position, 1)
        end

        it "should take into account position of the option_type " do
          tree = subject.tree
          expect(tree["colour"]["pink"]["size"]["small"]["variant"]["in_stock"]).to be true
          expect(tree["colour"]["blue"]["size"]["small"]["variant"]["in_stock"]).to be true
          expect(tree["colour"]["pink"]["size"]["big"]["variant"]["in_stock"]).to be true
          expect(tree["colour"]["blue"]["size"]["big"]["variant"]["in_stock"]).to be true
          expect(tree["language"]["english"]["variant"]["in_stock"]).to be false
        end
      end


      context "supplier" do
        let!(:supplier1) { create(:supplier) }
        let!(:supplier2) { create(:supplier) }
        let!(:stock_item1) { create(:stock_item, supplier: supplier1, variant: variant_in_stock1) }
        let!(:stock_item2) { create(:stock_item, supplier: supplier2, variant: variant_in_stock1) }

        it "should take into account position of the option_type " do
          tree = subject.tree
          expect(tree["size"]["small"]["colour"]["pink"]["variant"]["suppliers"]).to match_array([nil, supplier1, supplier2])
        end
      end

      context "number" do
        it "should provide variant number" do
          tree = subject.tree
          expect(tree["size"]["small"]["colour"]["pink"]["variant"]["number"]).to eq variant_in_stock1.number
        end
      end

      context "image" do
        let(:image) { build(:image) }

        before do
          variant_in_stock1.images << image
        end

        it "should return the correct non targetted image" do
          tree = subject.tree
          image_url = image.attachment.url(:mini)
          expect(tree["size"]["small"]["colour"]["pink"]["variant"]["image_url"]).to eq image_url
        end

        context "variant has product variants with images" do

          let(:image_2) { build(:image) }

          before do
            variant_in_stock1.images = []
            variant_in_stock2.images << image_2
          end

          it "does not return another variant image" do
            tree = subject.tree
            expect(tree["size"]["small"]["colour"]["pink"]["variant"]["image_url"]).to be_nil
          end

        end

      end

      context "sale price" do

        let!(:sale_price) { create(:price, amount: BigDecimal.new('6'), sale: true, is_kit: false, variant: variant_in_stock1)}

        before do
          variant_in_stock1.update_column(:in_sale, true)
        end

        it "should have sale_price" do
          tree = subject.tree
          attributes = tree["size"]["small"]["colour"]["pink"]["variant"]
          expect(attributes['in_sale']).to eq(true)
          expect(attributes['normal_price']).to eq(1999)
          expect(attributes['sale_price']).to eq(600)
          expect(attributes['part_price']).to eq(0)
        end

      end

      context "part price" do

        let!(:part_price) { create(:price, amount: BigDecimal.new('50'), sale: false, is_kit: true, variant: variant_in_stock1)}

        it "should have part_price" do
          tree = subject.tree
          attributes = tree["size"]["small"]["colour"]["pink"]["variant"]
          expect(attributes['normal_price']).to eq(1999)
          expect(attributes['sale_price']).to eq(0)
          expect(attributes['part_price']).to eq(5000)
          expect(attributes['in_sale']).to eq(false)
        end
      end

      context "currency" do

        let!(:gbp_price) { create(:price, amount: BigDecimal.new('7'), currency: 'GBP', variant: variant_in_stock1)}
        let(:currency) {'GBP'}

        it "should have sale_price" do
          tree = subject.tree
          attributes = tree["size"]["small"]["colour"]["pink"]["variant"]
          expect(attributes['in_sale']).to eq(false)
          expect(attributes['normal_price']).to eq(700)
          expect(attributes['sale_price']).to eq(0)
          expect(attributes['part_price']).to eq(0)
        end


      end

    end

    describe "#simple_variant_tree" do

      let!(:image) { create(:image) }

      before do
        variant_in_stock1.images << image
      end

      it "should return targeted variant_options_tree_for that are in stock " do
        tree = subject.simple_tree
        expect(tree["size"]["small"]["colour"]["pink"]["variant"]["in_stock"]).to be true
        expect(tree["size"]["small"]["colour"]["blue"]["variant"]["in_stock"]).to be true
        expect(tree["size"]["big"]["colour"]["pink"]["variant"]["in_stock"]).to be true
        expect(tree["size"]["big"]["colour"]["blue"]["variant"]["in_stock"]).to be true
        expect(tree["size"]["small"]["colour"]["pink"]["variant"]["number"]).to eq variant_in_stock1.number
        expect(tree["language"]["english"]).to_not be_nil

        image_url = image.attachment.url(:mini)
        expect(tree["size"]["small"]["colour"]["pink"]["variant"]["image_url"]).to eq image_url
      end

    end


    context "#option_type_order" do

      it "should return the order of the types" do
        expect(subject.option_type_order["size"]).to eq("colour")
        expect(subject.option_type_order["colour"]).to eq("language")
        expect(subject.option_type_order["language"]).to be_nil
      end

    end

    context "when passed in displayable_option_type" do

      subject { described_class.new(variants, currency, colour) }

      describe "tree" do
        it "returns the tree scoped by just the type" do
          tree = subject.simple_tree
          expect(tree["colour"]["pink"]["variant"]["in_stock"]).to be true
          expect(tree["colour"]["blue"]["variant"]["in_stock"]).to be true
          expect(tree["colour"]["pink"]["variant"]["number"]).to match(/#{variant_in_stock1.number}|#{variant_in_stock2.number}/)
        end
      end

      describe "option_values_in_stock" do

        it "returns scoped option values by type" do
          expect(subject.option_values_in_stock).to match_array([pink,blue])
        end

      end

    end

    context "Another build tree example" do

      let(:product) { create(:product_with_variants, amount: 19.99) }
      let(:supplier) { create(:supplier)}
      let(:variant_1) {product.variants[0] }
      let(:variant_2) {product.variants[1] }

      let(:variants) { [ variant_1, variant_2 ] }

      let(:ov1) { variant_1.option_values.first }
      let(:ov2) { variant_2.option_values.first }

      before do
        variant_1.stock_items.update_all(supplier_id: supplier.id)
        variant_2.stock_items.update_all(supplier_id: supplier.id)
      end

      it "should build a tree based on it's variants" do

        tree = subject.tree
        attributes = tree[ov1.option_type.name][ov1.name]['variant']

        expect(attributes).not_to be_nil
        expect(attributes["id"]).to eq(variant_1.id)
        expect(attributes["normal_price"]).to eq(1999)
        expect(attributes["sale_price"]).to eq(0)
        expect(attributes["part_price"]).to eq(0)
        expect(attributes["in_sale"]).to eq(false)
        expect(attributes["suppliers"]).to eq(variant_1.suppliers)

        attributes = tree[ov2.option_type.name][ov2.name]['variant']
        expect(attributes).not_to be_nil
        expect(attributes["id"]).to eq(variant_2.id)
        expect(attributes["normal_price"]).to eq(1999)
        expect(attributes["sale_price"]).to eq(0)
        expect(attributes["part_price"]).to eq(0)
        expect(attributes["in_sale"]).to eq(false)
        expect(attributes["suppliers"]).to eq(variant_2.suppliers)

        #product.variant_options_tree_for(nil,'GBP').should == {
        #  "color"=>{
        #    "hot-pink1"=>{
        #      "variant"=>{
        #        "id"=>2,
        #        "normal_price"=>1200,
        #        "sale_price"=>0,
        #        "in_sale"=>false}
        #    },
        #    "hot-pink2"=>{
        #      "variant"=>{
        #        "id"=>3,
        #        "normal_price"=>1200,
        #        "sale_price"=>0,
        #        "in_sale"=>false
        #      }
        #    }
        #  }
        #}
      end
    end

  end
end

