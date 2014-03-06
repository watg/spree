# coding: UTF-8

require 'spec_helper'

module ThirdParty
  class Extension < ActiveRecord::Base
    # nasty hack so we don't have to create a table to back this fake model
    self.table_name = 'spree_products'
  end
end

describe Spree::Product do
  context 'product instance' do
    let(:product) { create(:product) }

    context '#option_values_for' do
      before do
        Spree::StockItem.any_instance.stub(backorderable: false)
      end
      subject { create(:product) }
      let(:women)              { create(:target, name: 'women') }
      let!(:variant_out_stock) { create(:variant, product: subject, target: women) }
      let!(:variant_in_stock)  { create(:variant_with_stock_items, product: subject, target: women) }

      it "for made_by_the_gang" do
        expect(subject.option_values_for(women)).to match_array(variant_in_stock.option_values)
      end

      it "for kit" do
        subject  = create(:product, product_type: :kit)
        subject.save

        _kit_variant1 = create(:variant, product: subject, target: women, in_stock_cache: false)
        kit_variant2 = create(:variant, product: subject, target: women, in_stock_cache: true)
        kit_variant3 = create(:variant, product: subject, target: women, in_stock_cache: true)

        option_values = kit_variant2.option_values + kit_variant3.option_values
        expect(subject.option_values_for(women)).to match_array(option_values)
      end
    end

    context '#duplicate' do
      before do
        product.stub :taxons => [create(:taxon)]
      end

      it 'duplicates product' do
        clone = product.duplicate
        clone.name.should == 'COPY OF ' + product.name
        clone.master.sku.should == 'COPY OF ' + product.master.sku
        clone.taxons.should == product.taxons
        clone.images.size.should == product.images.size
      end

      it 'calls #duplicate_extra' do
        Spree::Product.class_eval do
          def duplicate_extra(old_product)
            self.name = old_product.name.reverse
          end
        end

        clone = product.duplicate
        clone.name.should == product.name.reverse

        Spree::Product.send(:remove_method, :duplicate_extra)
      end
    end

    context "product has no variants" do
      context "#destroy" do
        it "should set deleted_at value" do
          product.destroy
          product.deleted_at.should_not be_nil
          product.master.deleted_at.should_not be_nil
        end
      end
    end

    context "product has variants" do
      before do
        create(:variant, :product => product)
      end

      context "#destroy" do
        it "should set deleted_at value" do
          product.destroy
          product.deleted_at.should_not be_nil
          product.variants_including_master.all? { |v| !v.deleted_at.nil? }.should be_true
        end
      end
    end

    context "#price" do
      # Regression test for #1173
      it 'strips non-price characters' do
        product = create(:product_with_prices)
        product.price.to_s.should == '19.99'
      end
    end

    context "#display_price" do
      before do
        create(:price, variant_id: product.master.id, price: 19.99, currency: 'USD')
      end

      context "with display_currency set to true" do
        before { Spree::Config[:display_currency] = true }

        it "shows the currency" do
          product.display_price.to_s.should == "$19.99 USD"
        end
      end

      context "with display_currency set to false" do
        before { Spree::Config[:display_currency] = false }

        it "does not include the currency" do
          product.display_price.to_s.should == "$19.99"
        end
      end

      context "with currency set to JPY" do
        before do
          Spree::Config[:currency] = 'JPY'
        end

        it "displays the currency in yen" do
          create(:price, variant_id: product.master.id, price: 11.00, currency: 'JPY')
          product.display_price.to_s.should == "¥11"
        end
      end
    end

    context "#available?" do
      it "should be available if date is in the past" do
        product.available_on = 1.day.ago
        product.should be_available
      end

      it "should not be available if date is nil or in the future" do
        product.available_on = nil
        product.should_not be_available

        product.available_on = 1.day.from_now
        product.should_not be_available
      end
    end

    context "variants_and_option_values" do
      let!(:high) { create(:variant, product: product) }
      let!(:low) { create(:variant, product: product) }

      before { high.option_values.destroy_all }

      it "returns only variants with option values" do
        product.variants_and_option_values.should == [low]
      end
    end

    describe 'Variants sorting' do
      context 'without master variant' do
        it 'sorts variants by position' do
          product.variants.to_sql.should match(/ORDER BY (\`|\")spree_variants(\`|\").position ASC/)
        end
      end

      context 'with master variant' do
        it 'sorts variants by position' do
          product.variants_including_master.to_sql.should match(/ORDER BY (\`|\")spree_variants(\`|\").position ASC/)
        end
      end
    end

    context 'variants_for' do
      subject { create(:product) }
      let(:women)         { create(:target, name: 'women') }
      let(:men)           { create(:target, name: 'men') }
      let(:women_variant) { create(:variant, product: subject, target: women) }
      let(:men_variant)   { create(:variant, product: subject, target: men) }

      it 'returns variants for a given target' do
        expect(subject.variants_for(women)).to include(women_variant)
      end

      it 'returns all variants for no target' do
        expect(subject.variants_for(nil)).to include(women_variant,men_variant)
      end

    end

    context "has stock movements" do
      let(:product) { create(:product) }
      let(:variant) { product.master }
      let(:stock_item) { variant.stock_items.first }

      it "doesnt raise ReadOnlyRecord error" do
        Spree::StockMovement.create!(stock_item: stock_item, quantity: 1)
        expect { product.destroy }.not_to raise_error
      end
    end

    # Regression test for #3737
    context "has stock items" do
      let(:product) { create(:product) }
      it "can retreive stock items" do
        product.master.stock_items.first.should_not be_nil
        product.stock_items.first.should_not be_nil
      end
    end
  end

  context "permalink" do
    context "build product with similar name" do
      let!(:other) { create(:product, :name => 'foo bar') }
      let(:product) { build(:product, :name => 'foo') }

      before { product.valid? }

      it "increments name" do
        product.permalink.should == 'foo-1'
      end
    end

    context "build permalink with quotes" do
      it "saves quotes" do
        product = create(:product, :name => "Joe's", :permalink => "joe's")
        product.permalink.should == "joe's"
      end
    end

    context "permalinks must be unique" do
      before do
        @product1 = create(:product, :name => 'foo')
      end

      it "cannot create another product with the same permalink" do
        @product2 = create(:product, :name => 'foo')
        lambda do
          @product2.update_attributes(:permalink => @product1.permalink)
        end.should raise_error(ActiveRecord::RecordNotUnique)
      end
    end

    it "supports Chinese" do
      create(:product, :name => "你好").permalink.should == "ni-hao"
    end

    context "manual permalink override" do
      let(:product) { create(:product, :name => "foo") }

      it "calling save_permalink with a parameter" do
        product.name = "foobar"
        product.save
        product.permalink.should == "foo"

        product.save_permalink(product.name)
        product.permalink.should == "foobar"
      end
    end

    context "override permalink of deleted product" do
      let(:product) { create(:product, :name => "foo") }

      it "should create product with same permalink from name like deleted product" do
        product.permalink.should == "foo"
        product.destroy

        new_product = create(:product, :name => "foo")
        new_product.permalink.should == "foo"
      end
    end
  end

  context "properties" do
    let(:product) { create(:product) }

    it "should properly assign properties" do
      product.set_property('the_prop', 'value1')
      product.property('the_prop').should == 'value1'

      product.set_property('the_prop', 'value2')
      product.property('the_prop').should == 'value2'
    end

    it "should not create duplicate properties when set_property is called" do
      expect {
        product.set_property('the_prop', 'value2')
        product.save
        product.reload
      }.not_to change(product.properties, :length)

      expect {
        product.set_property('the_prop_new', 'value')
        product.save
        product.reload
        product.property('the_prop_new').should == 'value'
      }.to change { product.properties.length }.by(1)
    end

    # Regression test for #2455
    it "should not overwrite properties' presentation names" do
      Spree::Property.where(:name => 'foo').first_or_create!(:presentation => "Foo's Presentation Name")
      product.set_property('foo', 'value1')
      product.set_property('bar', 'value2')
      Spree::Property.where(:name => 'foo').first.presentation.should == "Foo's Presentation Name"
      Spree::Property.where(:name => 'bar').first.presentation.should == "bar"
    end
  end

  context '#create' do
    before do
      @prototype = create(:prototype)
      @product = build(:base_product)
    end

    context "when prototype is supplied" do
      before { @product.prototype_id = @prototype.id }

      it "should create properties based on the prototype" do
        @product.save!
        @product.properties.count.should == 1
      end

    end

    context "when prototype with option types is supplied" do
      def build_option_type_with_values(name, values)
        ot = create(:option_type, :name => name)
        values.each do |val|
          ot.option_values.create(:name => val.downcase, :presentation => val)
        end
        ot
      end

      let(:prototype) do
        size = build_option_type_with_values("size", %w(Small Medium Large))
        create(:prototype, :name => "Size", :option_types => [ size ])
      end

      let(:option_values_hash) do
        hash = {}
        prototype.option_types.each do |i|
          hash[i.id.to_s] = i.option_value_ids
        end
        hash
      end

      before { @product.prototype_id = prototype.id }

      it "should create option types based on the prototype" do
        @product.save
        @product.option_type_ids.length.should == 1
        @product.option_type_ids.should == prototype.option_type_ids
      end

      it "should create product option types based on the prototype" do
        @product.save
        @product.product_option_types.pluck(:option_type_id).should == prototype.option_type_ids
      end

      it "should create variants from an option values hash with one option type" do
        pending("decorator failure #important")
        @product.option_values_hash = option_values_hash
        @product.save
        @product.variants.length.should == 3
      end

      it "should still create variants when option_values_hash is given but prototype id is nil" do
        pending("decorator failure #important")
        @product.option_values_hash = option_values_hash
        @product.prototype_id = nil
        @product.save
        @product.option_type_ids.length.should == 1
        @product.option_type_ids.should == prototype.option_type_ids
        @product.variants.length.should == 3
      end

      it "should create variants from an option values hash with multiple option types" do
        pending("decorator failure #important")
        color = build_option_type_with_values("color", %w(Red Green Blue))
        logo  = build_option_type_with_values("logo", %w(Ruby Rails Nginx))
        option_values_hash[color.id.to_s] = color.option_value_ids
        option_values_hash[logo.id.to_s] = logo.option_value_ids
        @product.option_values_hash = option_values_hash
        @product.save
        @product = @product.reload
        @product.option_type_ids.length.should == 3
        @product.variants.length.should == 27
      end
    end

  end

  context "#images" do
    let(:product) { create(:product) }
    let(:image) { File.open(File.expand_path('../../../fixtures/thinking-cat.jpg', __FILE__)) }
    let(:params) { {:viewable_id => product.master.id, :viewable_type => 'Spree::Variant', :attachment => image, :alt => "position 2", :position => 2} }

    before do
      WebMock.disable!
      Spree::Image.create(params)
      Spree::Image.create(params.merge({:alt => "position 1", :position => 1}))
      Spree::Image.create(params.merge({:viewable_type => 'ThirdParty::Extension', :alt => "position 1", :position => 2}))
    end

    after do
      WebMock.enable!
    end

    it "only looks for variant images" do
      product.images.size.should == 2
    end

    it "should be sorted by position" do
      product.images.pluck(:alt).should eq(["position 1", "position 2"])
    end
  end

  context "#option_type_order" do
    let(:product) do
      size = build_option_type_with_values("size", %w(Small Medium Large), 0 )
      color = build_option_type_with_values("color", %w(red green), 1 )
      create(:product, :option_types => [ color, size ])
    end

    it "should return the order of the types" do
      product.option_type_order["size"].should == "color"
      product.option_type_order["color"].should be_nil
    end
  end

  context "Option Values, Targets and Stock" do

    let(:size)     { create(:option_type, name: 'size', position: 1 )}
    let(:big)      { create(:option_value, name: 'big', option_type: size, position: 0) }
    let(:small)    { create(:option_value, name: 'small', option_type: size, position: 1) }

    let(:colour)   { create(:option_type, name: 'colour', position: 2 )}
    let(:pink)     { create(:option_value, name: 'pink', option_type: colour, position: 0) }
    let(:blue)     { create(:option_value, name: 'blue', option_type: colour, position: 1) }

    let(:language) { create(:option_type, name: 'language', position: 3 )}
    let(:french)   { create(:option_value, name: 'french', option_type: language, position: 0) }
    let(:english)   { create(:option_value, name: 'english', option_type: language, position: 1) }

    let(:women) { create(:target, name:'Women') }
    let(:men)   { create(:target, name:'Men') }
    subject     { create(:base_product) }

    let!(:variant_in_stock1)  { create(:variant_with_stock_items, product: subject, target: women, option_values: [pink,small] ) }
    let!(:variant_in_stock2)  { create(:variant_with_stock_items, product: subject, target: women, option_values: [pink,big] ) }
    let!(:variant_in_stock3)  { create(:variant_with_stock_items, product: subject, target: women, option_values: [blue,small] ) }
    let!(:variant_in_stock4)  { create(:variant_with_stock_items, product: subject, target: women, option_values: [blue,big] ) }
    let!(:variant_out_stock) { create(:variant, product: subject, target: women, option_values: [english]) }
    let!(:variant_in_stock_men)  { create(:variant_with_stock_items, product: subject, target: men, option_values: [french] ) }

    before do
      Spree::StockItem.any_instance.stub(backorderable: false)
    end

    context "#option_values" do
      it "should return untargetted and instock items" do
        expect(subject.option_values).to eq([big,small,pink,blue,french])
      end
    end

    context "#option_values_for" do
      it "should return targetted and instock items" do
        expect(subject.option_values_for(women)).to eq([big,small,pink,blue])
      end
      it "should return untargetted and instock items" do
        expect(subject.option_values_for(nil)).to eq([big,small,pink,blue,french])
      end
    end

    context "#grouped_option_values" do
      it "should return untargetted and instock items" do
        expect(subject.grouped_option_values).to eq({ size => [big,small], colour => [pink,blue], language => [french]})
      end
    end

    context "#grouped_option_values_for" do
      it "should return targeted grouped_option_values_for that are in stock " do
        expect(subject.grouped_option_values_for(women)).to eq({ size => [big,small], colour => [pink,blue]})
      end

      it "should return not_tareted grouped_option_values_for that are in stock " do
        expect(subject.grouped_option_values_for(nil)).to eq({ size => [big,small], colour => [pink,blue], language =>[french]})
      end

    end

    context "#variant_options_tree_for" do
      it "should return targeted variant_options_tree_for that are in stock " do
        tree = subject.variant_options_tree_for(women,'USD')
        expect(tree["size"]["small"]["colour"]["pink"]["variant"]["in_stock"]).to be_true
        expect(tree["size"]["small"]["colour"]["blue"]["variant"]["in_stock"]).to be_true
        expect(tree["size"]["big"]["colour"]["pink"]["variant"]["in_stock"]).to be_true
        expect(tree["size"]["big"]["colour"]["blue"]["variant"]["in_stock"]).to be_true
        expect(tree["language"]["french"]).to be_nil
        expect(tree["language"]["english"]["in_stock"]).to be_false
      end

      it "should return untargeted variant_options_tree_for that are in stock " do
        tree = subject.variant_options_tree_for(nil,'USD')
        expect(tree["size"]["small"]["colour"]["pink"]["variant"]["in_stock"]).to be_true
        expect(tree["size"]["small"]["colour"]["blue"]["variant"]["in_stock"]).to be_true
        expect(tree["size"]["big"]["colour"]["pink"]["variant"]["in_stock"]).to be_true
        expect(tree["size"]["big"]["colour"]["blue"]["variant"]["in_stock"]).to be_true
        expect(tree["language"]["french"]["variant"]["in_stock"]).to be_true
        expect(tree["language"]["english"]["in_stock"]).to be_false
      end

    end

  end

  context "#variant_options_tree" do
    let(:product) { create(:product_with_variants) }
    let(:variant_in_sale) { create(:variant_in_sale) }

    it "should build a tree based on it's variants" do
      variant_1 = product.variants[0]
      variant_2 = product.variants[1]
      ov1 = variant_1.option_values.first
      ov2 = variant_2.option_values.first

      attributes = product.variant_options_tree_for(nil,'USD')[ov1.option_type.name][ov1.name]['variant']
      attributes.should_not be_nil
      attributes["id"].should == variant_1.id
      attributes["normal_price"].should == 1999
      attributes["sale_price"].should == 0
      attributes["part_price"].should == 0
      attributes["in_sale"].should == false

      attributes = product.variant_options_tree_for(nil,'USD')[ov2.option_type.name][ov2.name]['variant']
      attributes.should_not be_nil
      attributes["id"].should == variant_2.id
      attributes["normal_price"].should == 1999
      attributes["sale_price"].should == 0
      attributes["part_price"].should == 0
      attributes["in_sale"].should == false

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

    it "should have prices in USD" do
      variant = product.variants[0]
      ov = variant.option_values.first
      attributes = product.variant_options_tree_for(nil,'USD')[ov.option_type.name][ov.name]['variant']
      attributes['normal_price'].should == 1999
      attributes['sale_price'].should == 0
      attributes['part_price'].should == 0
      attributes['in_sale'].should == false
    end

    it "should have sale_price" do
      ov = variant_in_sale.option_values.first
      attributes = variant_in_sale.product.variant_options_tree_for(nil,'USD')[ov.option_type.name][ov.name]['variant']
      attributes['normal_price'].should == 1999
      attributes['sale_price'].should == 600
      attributes['part_price'].should == 0
      attributes['in_sale'].should == true
    end

    it "should have sale_price" do
      ov = variant_in_sale.option_values.first
      variant_in_sale.prices.create( currency: 'USD', sale: false, is_kit: true, amount: 50 ) 
      attributes = variant_in_sale.product.variant_options_tree_for(nil,'USD')[ov.option_type.name][ov.name]['variant']
      attributes['normal_price'].should == 1999
      attributes['sale_price'].should == 600
      attributes['part_price'].should == 5000
      attributes['in_sale'].should == true
    end

  end

  # Regression tests for #2352
  context "classifications and taxons" do
    it "is joined through classifications" do
      reflection = Spree::Product.reflect_on_association(:taxons)
      expect(reflection.options[:through]).to eq(:classifications)
    end

    it "will delete all classifications" do
      reflection = Spree::Product.reflect_on_association(:classifications)
      expect(reflection.options[:dependent]).to eq(:delete_all)
    end
  end

  describe '#total_on_hand' do
    it 'should be infinite if track_inventory_levels is false' do
      Spree::Config[:track_inventory_levels] = false
      build(:product, :variants_including_master => [build(:master_variant)]).total_on_hand.should eql(Float::INFINITY)
    end

    it 'should be infinite if variant is on demand' do
      Spree::Config[:track_inventory_levels] = true
      build(:product, :variants_including_master => [build(:on_demand_master_variant)]).total_on_hand.should eql(Float::INFINITY)
    end

    it 'should return sum of stock items count_on_hand' do
      product = build(:product)
      product.stub stock_items: [double(Spree::StockItem, count_on_hand: 5)]
      product.total_on_hand.should eql(5)
    end
  end

  def build_option_type_with_values(name, values, pos)
    ot = create(:option_type, :name => name, :position => pos)
    values.each do |val|
      ot.option_values.create(:name => val.downcase, :presentation => val)
    end
    ot
  end

  describe "touching" do

    let(:product_group) { create(:product_group) }
    let(:kit) { create(:product, product_group: product_group, product_type: "kit") }

    it "updates a product_group" do
      product_group.update_column(:updated_at, 1.day.ago)
      kit.touch
      product_group.reload.updated_at.should be_within(3.seconds).of(Time.now)
    end

  end


end
