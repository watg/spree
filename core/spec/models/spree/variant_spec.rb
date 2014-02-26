# encoding: utf-8

require 'spec_helper'

describe Spree::Variant do
  let!(:variant) { create(:variant) }

  context "stock control" do
    let!(:variant_in_stock) { create(:variant_with_stock_items, product_id: variant.product.id) }

    it "checks stock level" do
      Spree::StockItem.any_instance.stub(backorderable: false)
      expect(variant_in_stock.out_of_stock?).to be_false
      expect(variant.out_of_stock?).to be_true
    end

  end

  context "#generate_variant_number" do
    it "should generate a random string" do
      variant.generate_variant_number.is_a?(String).should be_true
      (variant.generate_variant_number.to_s.length > 0).should be_true
    end

    it "should not if one already exists" do
      variant.number = 123
      expect(variant.generate_variant_number).to eq 123
    end

    it "should if one already exists but force is true" do
      variant.number = 123
      expect(variant.generate_variant_number(force: true)).to_not eq 123
    end
  end

  context "#is_number" do
    it "should return true if number" do
      expect(Spree::Variant.is_number('V123123123')).to eq true
    end

    it "should return false if not a number" do
      expect(Spree::Variant.is_number('123123123')).to eq false
    end
  end

  context "weight" do

    context "for product" do
      subject { create(:variant, weight: 12.0) }
      its(:weight) { should == 12.0 }

      it "returns product master variant weight when own weight is not set" do
        variant_no_weight = create(:variant, product: create(:product, weight: 33.0), weight: nil)
        expect(variant_no_weight.weight).to eql(33.0)
      end
    end

    context "for kit" do
      subject { create(:variant, weight: 12.0, parts: [ create(:part, weight: 5.0)] ) }
      its(:weight) { should == 5.0 }
    end
  end

  context "after create" do
    let!(:product) { create(:product) }

    it "propagate to stock items" do
      Spree::StockLocation.any_instance.should_receive(:propagate_variant)
      product.variants.create(:name => "Foobar")
    end

    context "stock location has disable propagate all variants" do
      before { Spree::StockLocation.any_instance.stub(propagate_all_variants?: false) }

      it "propagate to stock items" do
        Spree::StockLocation.any_instance.should_not_receive(:propagate_variant)
        product.variants.create(:name => "Foobar")
      end
    end
  end

  context "product has other variants" do
    describe "option value accessors" do
      before {
        @multi_variant = FactoryGirl.create :variant, :product => variant.product
        variant.product.reload
      }

      let(:multi_variant) { @multi_variant }

      it "should set option value" do
        multi_variant.option_value('media_type').should be_nil

        multi_variant.set_option_value('media_type', 'DVD')
        multi_variant.option_value('media_type').should == 'DVD'

        multi_variant.set_option_value('media_type', 'CD')
        multi_variant.option_value('media_type').should == 'CD'
      end

      it "should not duplicate associated option values when set multiple times" do
        multi_variant.set_option_value('media_type', 'CD')

        expect {
         multi_variant.set_option_value('media_type', 'DVD')
        }.to_not change(multi_variant.option_values, :count)

        expect {
          multi_variant.set_option_value('coolness_type', 'awesome')
        }.to change(multi_variant.option_values, :count).by(1)
      end
    end

    context "product has other variants" do
      describe "option value accessors" do
        before {
          @multi_variant = create(:variant, :product => variant.product)
          variant.product.reload
        }

        let(:multi_variant) { @multi_variant }

        it "should set option value" do
          multi_variant.option_value('media_type').should be_nil

          multi_variant.set_option_value('media_type', 'DVD')
          multi_variant.option_value('media_type').should == 'DVD'

          multi_variant.set_option_value('media_type', 'CD')
          multi_variant.option_value('media_type').should == 'CD'
        end

        it "should not duplicate associated option values when set multiple times" do
          multi_variant.set_option_value('media_type', 'CD')

          expect {
           multi_variant.set_option_value('media_type', 'DVD')
          }.to_not change(multi_variant.option_values, :count)

          expect {
            multi_variant.set_option_value('coolness_type', 'awesome')
          }.to change(multi_variant.option_values, :count).by(1)
        end
      end
    end
  end

  context "::options_by_product" do
    let(:product) { FactoryGirl.create(:product_with_variants) }
    let(:option_value) { product.variants.first.option_values.first.name }

    it "should find a selected variant" do
      variant = Spree::Variant.options_by_product(product, [option_value])
      expect(variant).to eq(product.variants.first)
    end
  end

  context "#prices for a part" do
    let(:subject) { FactoryGirl.build(:part) }

    [:normal, :normal_sale, :part, :part_sale].each do |price_type|
      it "should return price for '#{price_type}'" do
        price = subject.price_for_type(price_type, 'GBP')
        expect(price).to be_a_kind_of(Spree::Price)
      end

      it "should have price type '#{price_type}'" do
        expect(subject.price_types).to include(price_type)
      end
    end
  end

  context "#prices for a product" do
    [:normal, :normal_sale].each do |price_type|
      it "should return price for '#{price_type}'" do
        price = subject.price_for_type(price_type, 'GBP')
        expect(price).to be_a_kind_of(Spree::Price)
      end

      it "should have price type '#{price_type}'" do
        expect(subject.price_types).to include(price_type)
      end
    end
  end

  context "price parsing" do
    before(:each) do
      I18n.locale = I18n.default_locale
      I18n.backend.store_translations(:de, { :number => { :currency => { :format => { :delimiter => '.', :separator => ',' } } } })
    end

    after do
      I18n.locale = I18n.default_locale
    end

    context "cost_price=" do
      context "with decimal point" do
        it "captures the proper amount for a formatted price" do
          variant.cost_price = '1,599.99'
          variant.cost_price.should == 1599.99
        end
      end

      context "with decimal comma" do
        it "captures the proper amount for a formatted price" do
          I18n.locale = :de
          variant.cost_price = '1.599,99'
          variant.cost_price.should == 1599.99
        end
      end

      context "with a numeric price" do
        it "uses the price as is" do
          I18n.locale = :de
          variant.cost_price = 1599.99
          variant.cost_price.should == 1599.99
        end
      end
    end
  end

  context "#currency" do
    it "returns the globally configured currency" do
      variant.currency.should == "USD"
    end
  end

  context "#display_amount" do
    it "returns a Spree::Money" do
      variant.display_amount.to_s.should == "$19.99"
    end
  end

  context "#cost_currency" do
    context "when cost currency is nil" do
      before { variant.cost_currency = nil }
      it "populates cost currency with the default value on save" do
        variant.save!
        variant.cost_currency.should == "USD"
      end
    end
  end

  describe '.price_normal_in' do
    before do
      variant.prices << create(:price, :variant => variant, :currency => "EUR", :amount => 33.33)
      variant.prices << create(:price, :variant => variant, :currency => "USD", :amount => 19.99)
    end
    subject { variant.price_normal_in(currency).display_amount }

    context "when currency is not specified" do
      let(:currency) { nil }

      it "returns 0" do
        subject.to_s.should == "$0.00"
      end
    end

    context "when currency is EUR" do
      let(:currency) { 'EUR' }

      it "returns the value in the EUR" do
        subject.to_s.should == "€33.33"
      end
    end

    context "when currency is USD" do
      let(:currency) { 'USD' }

      it "returns the value in the USD" do
        subject.to_s.should == "$19.99"
      end
    end
  end

  describe '.amount_in' do
    before do
      variant.prices << create(:price, :variant => variant, :currency => "EUR", :amount => 33.33)
      variant.prices << create(:price, :variant => variant, :currency => "USD", :amount => 19.99)
    end

    subject { variant.amount_in(currency) }

    context "when currency is not specified" do
      let(:currency) { nil }

      it "returns nil" do
        subject.should be_nil
      end
    end

    context "when currency is EUR" do
      let(:currency) { 'EUR' }

      it "returns the value in the EUR" do
        subject.should == 33.33
      end
    end

    context "when currency is USD" do
      let(:currency) { 'USD' }

      it "returns the value in the USD" do
        subject.should == 19.99
      end
    end
  end

  # Regression test for #2432
  describe 'options_text' do
    before do
      option_type = double("OptionType", :presentation => "Foo")
      option_values = [double("OptionValue", :option_type => option_type, :presentation => "bar")]
      variant.stub(:option_values).and_return(option_values)
    end

    it "orders options correctly" do
      variant.option_values.should_receive(:joins).with(:option_type).and_return(scope = double)
      scope.should_receive(:order).with('spree_option_types.position asc').and_return(variant.option_values)
      variant.options_text
    end
  end

  # Regression test for #2744
  describe "set_position" do
    it "sets variant position after creation" do
      variant = create(:variant)
      variant.position.should_not be_nil
    end
  end

  describe '#in_stock?' do
    before do
      Spree::Config.track_inventory_levels = true
    end

    context 'when stock_items are not backorderable' do
      before do
        Spree::StockItem.any_instance.stub(backorderable: false)
      end

      context 'when stock_items in stock' do
        before do
          variant.stock_items.first.update_column(:count_on_hand, 10)
        end

        it 'returns true if stock_items in stock' do
          variant.in_stock?.should be_true
        end
      end

      context 'when stock_items out of stock' do
        before do
          Spree::StockItem.any_instance.stub(backorderable: false)
          Spree::StockItem.any_instance.stub(count_on_hand: 0)
        end

        it 'return false if stock_items out of stock' do
          variant.in_stock?.should be_false
        end
      end

      context 'when providing quantity param' do
        before do
          variant.stock_items.first.update_attribute(:count_on_hand, 10)
        end

        it 'returns correctt value' do
          variant.in_stock?.should be_true
          variant.in_stock?(2).should be_true
          variant.in_stock?(10).should be_true
          variant.in_stock?(11).should be_false
        end
      end
    end

    context 'when stock_items are backorderable' do
      before do
        Spree::StockItem.any_instance.stub(backorderable: true)
      end

      context 'when stock_items out of stock' do
        before do
          Spree::StockItem.any_instance.stub(count_on_hand: 0)
        end

        it 'returns true if stock_items in stock' do
          variant.in_stock?.should be_true
        end
      end
    end

    describe "with tags" do
      let(:tags) { 2.times.map { FactoryGirl.create(:tag) } }

      before :each do
        subject.tags = tags
      end

      its(:tag_names) { should eq(tags.map(&:value)) }
    end
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

  context "Option Values, Targets and Stock" do
    let(:size)     { create(:option_type, name: 'size', position: 2 )}
    let(:big)      { create(:option_value, name: 'big', option_type: size, position: 0) }
    let(:small)    { create(:option_value, name: 'small', option_type: size, position: 1) }

    let(:colour)   { create(:option_type, name: 'colour', position: 1 )}
    let(:pink)     { create(:option_value, name: 'pink', option_type: colour, position: 0) }
    let(:blue)     { create(:option_value, name: 'blue', option_type: colour, position: 1) }

    let(:women)   { create(:target, name:'Women') }
    let(:base_product) { create(:base_product) }

    let!(:variant_in_stock)  { create(:variant_with_stock_items, product: base_product, target: women, option_values: [pink,small] ) }

    before do
      Spree::StockItem.any_instance.stub(backorderable: false)
    end

    context "#option_types_and_values" do
      it "should return non targetted option type and values" do
        expect(variant_in_stock.option_types_and_values).to eq([["colour", "pink", "Hot Pink"], ["size", "small", "Hot Pink"]])
      end
    end
  end

  describe "#images_for" do
    let(:variant) { create(:variant) }
    let!(:variant_images) { create_list(:image, 1, viewable: variant) }
    let(:target) { create(:target) }

    context "with a VariantTarget" do
      let(:variant_target) { create(:variant_target, variant: variant, target: target) }
      let(:variant_target_images) { create_list(:image, 1, viewable: variant_target) }
      let!(:images) { variant_target_images + variant_images }

      it "returns all images linked to the VariantTarget and Variant" do
        expect(variant.images_for(target)).to eq(images)
      end
    end

    context "with no VariantTarget" do
      it "returns all images linked to the Variant" do
        expect(variant.images_for(target)).to eq(variant_images)
      end
    end
  end

  describe "touching" do

    before { Delayed::Worker.delay_jobs = false }
    after { Delayed::Worker.delay_jobs = true }

    it "updates a product" do
      variant.product.update_column(:updated_at, 1.day.ago)
      variant.touch
      variant.product.reload.updated_at.should be_within(3.seconds).of(Time.now)
    end

    # This has been disabled as it was causing too much of a performance overhead
    it "updates it's kit and assemblies_parts" do
      part = create(:variant) 
      variant.add_part part
      ap = Spree::AssembliesPart.where(part_id: part.id).first
      ap.update_column(:updated_at, 1.day.ago)
      variant.update_column(:updated_at, 1.day.ago)
      part.touch
      ap.reload.updated_at.should be_within(3.seconds).of(Time.now)
      variant.reload.updated_at.should be_within(3.seconds).of(Time.now)
    end
  end

  describe "#should_track_inventory?" do

    it 'should not track inventory when global setting is off' do
      Spree::Config[:track_inventory_levels] = false

      build(:variant).should_track_inventory?.should eq(false)
    end

    it 'should not track inventory when variant is turned off' do
      Spree::Config[:track_inventory_levels] = true

      build(:on_demand_variant).should_track_inventory?.should eq(false)
    end

    it 'should track inventory when global and variant are on' do
      Spree::Config[:track_inventory_levels] = true

      build(:variant).should_track_inventory?.should eq(true)
    end
  end

  describe "deleted_at scope" do
    before { variant.destroy && variant.reload }
    it "should have a price if deleted" do
      variant.label = 'food'
      expect(variant.label).to eq('food')
    end
  end

end
