# encoding: utf-8
require 'spec_helper'

describe Spree::ProductOptionsPresenter do
  let(:women)              { build_stubbed(:target, name: 'women') }
  let(:men)                { build_stubbed(:target, name: 'women') }
  let(:target) { nil }
  let(:currency) { 'USD' }
  let(:product) { build_stubbed(:base_product) }
  let(:context) { { currency: currency, target: target}}

  subject { described_class.new(product, view, context) }

   describe '#option_values_in_stock' do

    let(:target) { women }

    before do
      Spree::StockItem.any_instance.stub(backorderable: false)
    end
    context "for made by the gang" do

      let!(:variant_out_stock) { create(:variant, product: product, target: women, label: 'women out of stock') }
      let!(:variant_in_stock1)  { create(:variant_with_stock_items, product: product, target: women, label: 'women') }
      let!(:variant_in_stock2)  { create(:variant_with_stock_items, product: product, target: men, label: 'men') }

      it "returns the correct option values" do
        expect(subject.option_values_in_stock).to match_array(variant_in_stock1.option_values)
      end

    end

    context "for kit" do
      let(:product) { create(:product, product_type: create(:product_type_kit)) }

      let!(:_kit_variant1) { create(:variant, product: product, target: women, in_stock_cache: false) }
      let!(:kit_variant2) { create(:variant, product: product, target: women, in_stock_cache: true) }
      let!(:kit_variant3) { create(:variant, product: product, target: women, in_stock_cache: true) }

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

    let!(:women) { create(:target, name:'Women') }
    let!(:men)   { create(:target, name:'Men') }

    let!(:variant_in_stock1)  { create(:variant_with_stock_items, product: product, target: women, option_values: [pink,small], amount: 19.99 ) }
    let!(:variant_in_stock2)  { create(:variant_with_stock_items, product: product, target: women, option_values: [pink,big], amount: 19.99 ) }
    let!(:variant_in_stock3)  { create(:variant_with_stock_items, product: product, target: women, option_values: [blue,small], amount: 19.99 ) }
    let!(:variant_in_stock4)  { create(:variant_with_stock_items, product: product, target: women, option_values: [blue,big], amount: 19.99 ) }
    let!(:variant_out_stock) { create(:variant, product: product, target: women, option_values: [english], amount: 19.99) }
    let!(:variant_in_stock_men)  { create(:variant_with_stock_items, product: product, target: men, option_values: [french], amount: 19.99 ) }

    before do
      Spree::StockItem.any_instance.stub(backorderable: false)
    end

    describe "#grouped_option_values_in_stock" do

      it "should return untargetted and instock items" do
        grouped_option_values_in_stock = subject.grouped_option_values_in_stock
        expect(grouped_option_values_in_stock[size]).to eq([big,small])
        expect(grouped_option_values_in_stock[colour]).to eq([pink,blue])
        expect(grouped_option_values_in_stock[language]).to eq([french])
      end

      context "men" do

        let(:target) { men }
        it "should return untargetted and instock items" do
          grouped_option_values_in_stock = subject.grouped_option_values_in_stock
          expect(grouped_option_values_in_stock[size]).to be_nil
          expect(grouped_option_values_in_stock[colour]).to be_nil
          expect(grouped_option_values_in_stock[language]).to eq([french])
        end
      end

      context "women" do
        let(:target) { women }
        it "should return untargetted and instock items" do
          grouped_option_values_in_stock = subject.grouped_option_values_in_stock
          expect(grouped_option_values_in_stock[size]).to eq([big,small])
          expect(grouped_option_values_in_stock[colour]).to eq([pink,blue])
          expect(grouped_option_values_in_stock[language]).to be_nil
        end
      end

    end

    describe "#variant_tree" do

      context "target and in_stock" do
        let(:target) { women }
        it "should return targeted variant_options_tree_for that are in stock " do
          tree = subject.variant_tree
          expect(tree["size"]["small"]["colour"]["pink"]["variant"]["in_stock"]).to be_true
          expect(tree["size"]["small"]["colour"]["blue"]["variant"]["in_stock"]).to be_true
          expect(tree["size"]["big"]["colour"]["pink"]["variant"]["in_stock"]).to be_true
          expect(tree["size"]["big"]["colour"]["blue"]["variant"]["in_stock"]).to be_true
          expect(tree["language"]["english"]).to_not be_nil
        end

        context "no target" do

          let(:target) { nil }
          it "should return untargeted variant_options_tree_for that are in stock " do
            tree = subject.variant_tree
            expect(tree["size"]["small"]["colour"]["pink"]["variant"]["in_stock"]).to be_true
            expect(tree["size"]["small"]["colour"]["blue"]["variant"]["in_stock"]).to be_true
            expect(tree["size"]["big"]["colour"]["pink"]["variant"]["in_stock"]).to be_true
            expect(tree["size"]["big"]["colour"]["blue"]["variant"]["in_stock"]).to be_true
            expect(tree["language"]["french"]["variant"]["in_stock"]).to be_true
            expect(tree["language"]["english"]["in_stock"]).to be_false
          end
        end
      end

      context "option_type positions" do

        before do
          size.update_column(:position, 2)
          colour.update_column(:position, 1)
        end

        it "should take into account position of the option_type " do
          tree = subject.variant_tree
          expect(tree["colour"]["pink"]["size"]["small"]["variant"]["in_stock"]).to be_true
          expect(tree["colour"]["blue"]["size"]["small"]["variant"]["in_stock"]).to be_true
          expect(tree["colour"]["pink"]["size"]["big"]["variant"]["in_stock"]).to be_true
          expect(tree["colour"]["blue"]["size"]["big"]["variant"]["in_stock"]).to be_true
          expect(tree["language"]["french"]["variant"]["in_stock"]).to be_true
          expect(tree["language"]["english"]["in_stock"]).to be_false
        end
      end

      context "total on hand" do
        let(:supplier) { create(:supplier) }
        let(:stock_item) { create(:stock_item, supplier: supplier, variant: variant_in_stock1) }

        before do
          stock_item.set_count_on_hand(10)
        end

        it "should take into account position of the option_type " do
          tree = subject.variant_tree
          expect(tree["size"]["small"]["colour"]["pink"]["variant"]["total_on_hand"]).to eq 20
        end
      end

      context "supplier" do
        let!(:supplier1) { create(:supplier) }
        let!(:supplier2) { create(:supplier) }
        let!(:stock_item1) { create(:stock_item, supplier: supplier1, variant: variant_in_stock1) }
        let!(:stock_item2) { create(:stock_item, supplier: supplier2, variant: variant_in_stock1) }

        it "should take into account position of the option_type " do
          tree = subject.variant_tree
          expect(tree["size"]["small"]["colour"]["pink"]["variant"]["suppliers"]).to match_array([nil, supplier1, supplier2])
        end
      end

      context "number" do
        it "should provide variant number" do
          tree = subject.variant_tree
          expect(tree["size"]["small"]["colour"]["pink"]["variant"]["number"]).to eq variant_in_stock1.number
        end
      end

      context "image" do
        let(:image) { build(:image) }

        before do
          variant_in_stock1.images << image
        end

        it "should return the correct non targetted image" do
          tree = subject.variant_tree
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
            tree = subject.variant_tree
            expect(tree["size"]["small"]["colour"]["pink"]["variant"]["image_url"]).to be_nil
          end

        end

        context "targetted image" do
          let(:target) { women }

          before do
            variant_in_stock1.targets = [women]
          end

          it "should return the correct targetted image" do
            tree = subject.variant_tree
            image_url = image.attachment.url(:mini)
            expect(tree["size"]["small"]["colour"]["pink"]["variant"]["image_url"]).to eq image_url
          end

          context "wrong target" do

            before do
              variant_in_stock1.targets = [men]
            end

            it "should return the correct targetted image" do
              tree = subject.variant_tree
              expect(tree["size"]["small"]["colour"]["pink"]).to be_nil
            end

          end

        end

      end

      context "sale price" do

        let!(:sale_price) { create(:price, amount: BigDecimal.new('6'), sale: true, is_kit: false, variant: variant_in_stock1)}

        before do
          variant_in_stock1.update_column(:in_sale, true)
        end

        it "should have sale_price" do
          tree = subject.variant_tree
          attributes = tree["size"]["small"]["colour"]["pink"]["variant"]
          attributes['in_sale'].should == true
          attributes['normal_price'].should == 1999
          attributes['sale_price'].should == 600
          attributes['part_price'].should == 0
        end

      end

      context "part price" do

        let!(:part_price) { create(:price, amount: BigDecimal.new('50'), sale: false, is_kit: true, variant: variant_in_stock1)}

        it "should have part_price" do
          tree = subject.variant_tree
          attributes = tree["size"]["small"]["colour"]["pink"]["variant"]
          attributes['normal_price'].should == 1999
          attributes['sale_price'].should == 0
          attributes['part_price'].should == 5000
          attributes['in_sale'].should == false
        end
      end

      context "currency" do

        let!(:gbp_price) { create(:price, amount: BigDecimal.new('7'), currency: 'GBP', variant: variant_in_stock1)}
        let(:currency) {'GBP'}

        it "should have sale_price" do
          tree = subject.variant_tree
          attributes = tree["size"]["small"]["colour"]["pink"]["variant"]
          attributes['in_sale'].should == false
          attributes['normal_price'].should == 700
          attributes['sale_price'].should == 0
          attributes['part_price'].should == 0
        end


      end

    end

    describe "#simple_variant_tree" do

      let(:target) { women }
      let!(:image) { create(:image) }

      before do
        variant_in_stock1.images << image
      end

      it "should return targeted variant_options_tree_for that are in stock " do
        tree = subject.simple_variant_tree
        expect(tree["size"]["small"]["colour"]["pink"]["variant"]["in_stock"]).to be_true
        expect(tree["size"]["small"]["colour"]["blue"]["variant"]["in_stock"]).to be_true
        expect(tree["size"]["big"]["colour"]["pink"]["variant"]["in_stock"]).to be_true
        expect(tree["size"]["big"]["colour"]["blue"]["variant"]["in_stock"]).to be_true
        expect(tree["size"]["small"]["colour"]["pink"]["variant"]["number"]).to eq variant_in_stock1.number
        expect(tree["language"]["english"]).to_not be_nil

        image_url = image.attachment.url(:mini)
        expect(tree["size"]["small"]["colour"]["pink"]["variant"]["image_url"]).to eq image_url
      end
    end


    context "#option_type_order" do

      it "should return the order of the types" do
        subject.option_type_order["size"].should == "colour"
        subject.option_type_order["colour"].should == "language"
        subject.option_type_order["language"].should be_nil
      end

    end

    context "Another build tree example" do

      let(:product) { create(:product_with_variants, amount: 19.99) }
      let(:supplier) { create(:supplier)}
      let(:variant_1) {product.variants[0] }
      let(:variant_2) {product.variants[1] }

      let(:ov1) { variant_1.option_values.first }
      let(:ov2) { variant_2.option_values.first }

      before do
        variant_1.stock_items.update_all(supplier_id: supplier.id)
        variant_2.stock_items.update_all(supplier_id: supplier.id)
      end

      it "should build a tree based on it's variants" do

        tree = subject.variant_tree
        attributes = tree[ov1.option_type.name][ov1.name]['variant']

        attributes.should_not be_nil
        attributes["id"].should == variant_1.id
        attributes["normal_price"].should == 1999
        attributes["sale_price"].should == 0
        attributes["part_price"].should == 0
        attributes["in_sale"].should == false
        attributes["total_on_hand"].should == variant_1.total_on_hand
        attributes["suppliers"].should == variant_1.suppliers

        attributes = tree[ov2.option_type.name][ov2.name]['variant']
        attributes.should_not be_nil
        attributes["id"].should == variant_2.id
        attributes["normal_price"].should == 1999
        attributes["sale_price"].should == 0
        attributes["part_price"].should == 0
        attributes["in_sale"].should == false
        attributes["total_on_hand"].should == variant_2.total_on_hand
        attributes["suppliers"].should == variant_2.suppliers

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

