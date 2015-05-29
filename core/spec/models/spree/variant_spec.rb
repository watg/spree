# encoding: utf-8

require 'spec_helper'

describe Spree::Variant, :type => :model do
  let!(:variant) { create(:variant) }

  context "variant navigation" do
    let(:product) { create(:base_product) }
    let(:product_2) { create(:base_product) }
    # Plesae note the order in which these are created
    # dictates the position attribute.
    let!(:previous_variant_from_product_2) { create(:base_variant, product: product_2) }
    let!(:previous_variant) { create(:base_variant, product: product) }
    let!(:middle_variant) { create(:base_variant, product: product ) }
    let!(:next_variant) { create(:base_variant, product: product) }
    let!(:next_variant_from_product_2) { create(:base_variant, product: product_2) }

    it "moves to the next variant" do
      expect(middle_variant.next).to eq next_variant
    end

    it "moves to the previous variant" do
      expect(middle_variant.previous).to eq previous_variant
    end

    it "does not return next if there is not one" do
      expect(next_variant.next).to be_nil
    end

    it "does not return previous if there is not one" do
      expect(previous_variant.previous).to be_nil
    end

  end

  context "stock control" do
    let!(:variant_in_stock) { create(:variant_with_stock_items, product_id: variant.product.id) }

    it "checks stock level" do
      allow_any_instance_of(Spree::StockItem).to receive_messages(backorderable: false)
      expect(variant_in_stock.in_stock?).to be true
      expect(variant.in_stock?).to be false
    end

  end

  context "create_sku" do
    let(:variant) { build(:base_variant, sku: 'asdasd') }

    it "builds the correct sku" do
      variant.product.master.sku = 'ABC'
      variant.create_sku
      expect(variant.sku).to match "ABC-COL-HO_PI"
    end

  end

  context "create_sku_if_not_present" do
    let(:variant) { build(:base_variant, sku: nil) }

    it "calls create_sku on a save" do
      variant.product.master.sku = 'ABC'
      expect(variant.sku).to be_nil
      variant.create_sku
      expect(variant.sku).to match "ABC-COL-HO_PI"
    end

    context "sku is present" do
      let(:variant) { build(:base_variant, sku: 'I am present') }

      it "does not call create_sku on a save" do
        expect(variant).to_not receive(:create_sku)
        variant.save
      end
    end

  end

  context "physical" do
    subject { Spree::Variant.physical }
    it { is_expected.not_to be_nil }
  end

  context "#generate_variant_number" do
    it "should generate a random string" do
      expect(variant.generate_variant_number.is_a?(String)).to be_truthy
      expect(variant.generate_variant_number.to_s.length > 0).to be_truthy
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

    subject { create(:variant, weight: 12.0) }

    describe '#weight' do
      subject { super().weight }
      it { is_expected.to eq(12.0) }
    end

    context "weight validation" do
      subject { Spree::Variant.new }
      # This has been disabled whilst we decide if we want this functionality
      # DD 26/03/14
      xit "weight cannot be nil for non - kit variant" do
        subject.valid?
        expect(subject.error_on(:weight)).to_not be_blank
      end

      # This has been disabled whilst we decide if we want this functionality
      # DD 26/03/14
      xit "weight can be nil for kit variant" do
        subject.product = create(:product, product_type: create(:product_type_kit) )
        subject.valid?
        expect(subject.error_on(:weight)).to be_blank
      end

    end
  end

  context "cost_price" do

    subject { create(:variant, cost_price: 12.0) }

    describe '#cost_price' do
      subject { super().cost_price }
      it { is_expected.to eq(12.0) }
    end

    context "cost_price validation" do
      subject { Spree::Variant.new }
      # This has been disabled whilst we decide if we want this functionality
      # DD 26/03/14
      xit "cost_price cannot be nil for non - kit variant" do
        subject.valid?
        expect(subject.error_on(:cost_price)).to_not be_blank
      end

      # This has been disabled whilst we decide if we want this functionality
      # DD 26/03/14
      xit "cost_price can be nil for kit variant" do
        subject.product = create(:product, product_type: create(:product_type_kit) )
        subject.valid?
        expect(subject.error_on(:cost_price)).to be_blank
      end

    end
  end


  context "after create" do
    let!(:product) { create(:product) }

    it "propagate to stock items" do
      expect_any_instance_of(Spree::StockLocation).to receive(:propagate_variant)
      product.variants.create(:name => "Foobar", weight: 10, cost_price: 10)
    end

    context "stock location has disable propagate all variants" do
      before { allow_any_instance_of(Spree::StockLocation).to receive_messages(propagate_all_variants?: false) }

      it "propagate to stock items" do
        expect_any_instance_of(Spree::StockLocation).not_to receive(:propagate_variant)
        product.variants.create(:name => "Foobar", weight: 10, cost_price: 10)
      end
    end

    describe 'mark_master_out_of_stock' do
      before { Delayed::Worker.delay_jobs = false }
      after { Delayed::Worker.delay_jobs = true }

      before do
        product.master.update_column(:in_stock_cache, true)
      end
      context 'when product is created without variants but with stock' do
        it { expect(product.master).to be_in_stock }
      end

      context 'when a variant is created' do

        before(:each) do
          product.variants.create!(:name => 'any-name')
        end
        it { expect(product.master).to_not be_in_stock }
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
        expect(multi_variant.option_value('media_type')).to be_nil

        multi_variant.set_option_value('media_type', 'DVD')
        expect(multi_variant.option_value('media_type')).to eql 'DVD'

        multi_variant.set_option_value('media_type', 'CD')
        expect(multi_variant.option_value('media_type')).to eql 'CD'
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
          expect(multi_variant.option_value('media_type')).to be_nil

          multi_variant.set_option_value('media_type', 'DVD')
          expect(multi_variant.option_value('media_type')).to eql 'DVD'

          multi_variant.set_option_value('media_type', 'CD')
          expect(multi_variant.option_value('media_type')).to eql 'CD'
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

  context "#prices types" do
    let(:product) { build(:product, can_be_part: true)}
    let(:subject) { FactoryGirl.build(:variant, product: product) }

    [:normal, :normal_sale, :part].each do |price_type|
      it "should return price for '#{price_type}'" do
        price = subject.price_for_type(price_type, 'GBP')
        expect(price).to be_a_kind_of(Spree::Price)
      end

    end
  end

  context "#cost_price=" do
    it "should use LocalizedNumber.parse" do
      expect(Spree::LocalizedNumber).to receive(:parse).with('1,599.99')
      subject.cost_price = '1,599.99'
    end
  end

  context "#price=" do
    it "should use LocalizedNumber.parse" do
      expect(Spree::LocalizedNumber).to receive(:parse).with('1,599.99')
      subject.price = '1,599.99'
    end
  end

  context "#weight=" do
    it "should use LocalizedNumber.parse" do
      expect(Spree::LocalizedNumber).to receive(:parse).with('1,599.99')
      subject.weight = '1,599.99'
    end
  end

  context "#currency" do
    it "returns the globally configured currency" do
      expect(variant.currency).to eql "USD"
    end
  end

  context "#display_amount" do
    it "returns a Spree::Money" do
      expect(variant.display_amount.to_s).to eq("$19.99")
    end
  end

  context "#cost_currency" do
    context "when cost currency is nil" do
      before { variant.cost_currency = nil }
      it "populates cost currency with the default value on save" do
        variant.save!
        expect(variant.cost_currency).to eql "USD"
      end
    end
  end

  describe '.price_normal_in' do
    subject { variant.price_normal_in(currency).display_amount }

    before do
      variant.price_normal_in('EUR').amount = 33.33
      variant.price_normal_in('USD').amount = 19.99
    end

    context "currency nil" do
      let(:currency) { nil }
      it { expect(subject.to_s).to eql "$0.00" }
    end

    context "currency is EUR" do
      let(:currency) { 'EUR' }
      it { expect(subject.to_s).to eql "€33.33" }
    end

    context "currency is USD" do
      let(:currency) { 'USD' }
      it { expect(subject.to_s).to eql "$19.99" }
    end
  end

  describe '.amount_in' do
    before do
      variant.price_normal_in('EUR').amount = 33.33
      variant.price_normal_in('USD').amount = 19.99
    end

    subject { variant.amount_in(currency) }

    context "when currency is not specified" do
      let(:currency) { nil }

      it "returns nil" do
        expect(subject).to be_nil
      end
    end

    context "when currency is EUR" do
      let(:currency) { 'EUR' }

      it "returns the value in the EUR" do
        expect(subject).to eql 33.33
      end
    end

    context "when currency is USD" do
      let(:currency) { 'USD' }

      it "returns the value in the USD" do
        expect(subject).to eql 19.99
      end
    end
  end

  # Regression test for #2432
  describe 'options_text' do
    let!(:variant) { create(:variant, option_values: []) }

    before do
      # Order bar than foo
      variant.option_values << create(:option_value, {name: 'Foo', presentation: 'Foo', option_type: create(:option_type, position: 2, name: 'Foo Type', presentation: 'Foo Type')})
      variant.option_values << create(:option_value, {name: 'Bar', presentation: 'Bar', option_type: create(:option_type, position: 1, name: 'Bar Type', presentation: 'Bar Type')})
    end

    it 'should order by bar than foo' do
      expect(variant.options_text).to eql 'Bar Type: Bar, Foo Type: Foo'
    end
  end

  # Regression test for #2744
  describe "set_position" do
    it "sets variant position after creation" do
      variant = create(:variant)
      expect(variant.position).to_not be_nil
    end
  end

  describe '#in_stock?' do
    before do
      Spree::Config.track_inventory_levels = true
    end

    context 'when stock_items are not backorderable' do
      before do
        allow_any_instance_of(Spree::StockItem).to receive_messages(backorderable: false)
      end

      context 'when stock_items in stock' do
        before do
          #variant.stock_items.first.update_column(:count_on_hand, 10)
          variant.update_column(:in_stock_cache, true)
        end

        it 'returns true if stock_items in stock' do
          expect(variant.in_stock?).to be true
        end
      end

      context 'when stock_items out of stock' do
        before do
          allow_any_instance_of(Spree::StockItem).to receive_messages(backorderable: false)
          allow_any_instance_of(Spree::StockItem).to receive_messages(count_on_hand: 0)
        end

        it 'return false if stock_items out of stock' do
          expect(variant.in_stock?).to be false
        end
      end
    end

    describe "#can_supply?" do
      it "calls out to quantifier" do
        expect(Spree::Stock::Quantifier).to receive(:new).and_return(quantifier = double)
        expect(quantifier).to receive(:can_supply?).with(10)
        variant.can_supply?(10)
      end
    end

    context 'when stock_items are backorderable' do
      before do
        allow_any_instance_of(Spree::StockItem).to receive_messages(backorderable: true)
      end

      context 'when stock_items out of stock' do
        before do
          allow_any_instance_of(Spree::StockItem).to receive_messages(count_on_hand: 0)
        end

        it 'in_stock? returns false' do
          expect(variant.in_stock?).to be false
        end

        it 'can_supply? return true' do
          expect(variant.can_supply?).to be true
        end
      end
    end

  end

  describe '#is_backorderable' do
    let(:variant) { build(:variant) }
    subject { variant.is_backorderable? }

    it 'should invoke Spree::Stock::Quantifier' do
      expect_any_instance_of(Spree::Stock::Quantifier).to receive(:backorderable?) { true }
      subject
    end
  end

  describe '#total_on_hand' do
    it 'should be infinite if track_inventory_levels is false' do
      Spree::Config[:track_inventory_levels] = false
      expect(build(:variant).total_on_hand).to eql(Float::INFINITY)
    end

    it 'should match quantifier total_on_hand' do
      variant = build(:variant)
      expect(variant.total_on_hand).to eq(Spree::Stock::Quantifier.new(variant).total_on_hand)
    end
  end

  describe '#tax_category' do
    context 'when tax_category is nil' do
      let(:product) { build(:product) }
      let(:variant) { build(:variant, product: product, tax_category_id: nil) }
      it 'returns the parent products tax_category' do
        expect(variant.tax_category).to eq(product.tax_category)
      end
    end

    context 'when tax_category is set' do
      let(:tax_category) { create(:tax_category) }
      let(:variant) { build(:variant, tax_category: tax_category) }
      it 'returns the tax_category set on itself' do
        expect(variant.tax_category).to eq(tax_category)
      end
    end
  end

  describe "touching" do
    it "updates a product" do
      variant.product.update_column(:updated_at, 1.day.ago)
      variant.touch
      expect(variant.product.reload.updated_at).to be_within(3.seconds).of(Time.now)
    end

    it "clears the in_stock cache key" do
      expect(Rails.cache).to receive(:delete).with(variant.send(:in_stock_cache_key))
      variant.touch
    end
  end

  describe "#should_track_inventory?" do

    it 'should not track inventory when global setting is off' do
      Spree::Config[:track_inventory_levels] = false

      expect(build(:variant).should_track_inventory?).to eq(false)
    end

    it 'should not track inventory when variant is turned off' do
      Spree::Config[:track_inventory_levels] = true

      expect(build(:on_demand_variant).should_track_inventory?).to eq(false)
    end

    it 'should track inventory when global and variant are on' do
      Spree::Config[:track_inventory_levels] = true

      expect(build(:variant).should_track_inventory?).to eq(true)
    end
  end

  describe "deleted_at scope" do
    before { variant.destroy && variant.reload }
    it "should have prices if deleted" do
      variant.price_normal_in('USD').amount = 10
      expect(variant.price_normal_in('USD').amount.to_i).to eq(10)
    end
  end

  describe "create_stock_items" do

    let(:variant) { build(:variant) }
    let(:supplier) { create(:supplier) }
    before { variant.supplier  = supplier}

    it "should pass the correct params" do
      expect_any_instance_of(Spree::StockLocation).to receive(:propagate_variant).with(variant, supplier)
      variant.save
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
      allow_any_instance_of(Spree::StockItem).to receive_messages(backorderable: false)
    end

    context "#option_types_and_values" do
      it "should return non targetted option type and values" do
        expect(variant_in_stock.option_types_and_values).to eq([["colour", "pink", "Hot Pink"], ["size", "small", "Hot Pink"]])
      end
    end
  end

  describe "#images_for" do
    let(:variant) { create(:variant) }
    let!(:variant_images) { create_list(:image, 1, viewable: variant, position: 2) }
    let(:target) { create(:target) }

    context "with a VariantTarget" do
      let(:variant_target) { create(:variant_target, variant: variant, target: target) }
      let(:variant_target_images) { create_list(:image, 1, viewable: variant, target: target, position: 1) }
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
      expect(variant.product.reload.updated_at).to be_within(3.seconds).of(Time.now)
    end

    context "assembly_definition_variants" do

      let(:assembly_definition_variant) { mock_model(Spree::AssemblyDefinitionVariant) }
      before do
        allow(variant).to receive(:assembly_definition_variants).and_return [ assembly_definition_variant ]
      end

      it "calls touch_assembly_definition_variants after touch" do
        expect(variant).to receive(:touch_assembly_definition_variants)
        variant.touch
      end

      it "touches it assembly_definition_variants" do
        expect(assembly_definition_variant).to receive(:touch)
        variant.touch
      end
    end


    # This has been disabled as it was causing too much of a performance overhead
    it "updates it's kit and assemblies_parts" do
      part = create(:variant)
      variant.add_part part
      ap = Spree::StaticAssembliesPart.where(part_id: part.id).first
      ap.update_column(:updated_at, 1.day.ago)
      variant.update_column(:updated_at, 1.day.ago)
      part.touch
      expect(ap.reload.updated_at).to be_within(3.seconds).of(Time.now)
      expect(variant.reload.updated_at).to be_within(3.seconds).of(Time.now)
    end

    context "Assembly Definition" do
      let(:assembly_definition) { create(:assembly_definition, variant: variant) }
      let(:variant_part)  { create(:variant) }
      let(:product_part)  { variant_part.product }
      let(:adp) { create(:assembly_definition_part, assembly_definition: assembly_definition, product: product_part) }
      let!(:adv) { create(:assembly_definition_variant, assembly_definition_part: adp, variant: variant_part) }


      # This is not needed for the time being
      it "touches assembly product after touch" do
        variant.product.update_column(:updated_at, 1.day.ago)
        variant_part.reload.touch
        expect(variant.product.reload.updated_at).to be_within(1.seconds).of(Time.now)
      end

      it "touches assembly product after save" do
        variant.product.update_column(:updated_at, 1.day.ago)
        variant_part.reload.save
        expect(variant.product.reload.updated_at).to be_within(1.seconds).of(Time.now)
      end

    end

  end

  describe "#should_track_inventory?" do

    it 'should not track inventory when global setting is off' do
      Spree::Config[:track_inventory_levels] = false

      expect(build(:variant).should_track_inventory?).to eq(false)
    end

    it 'should not track inventory when variant is turned off' do
      Spree::Config[:track_inventory_levels] = true

      expect(build(:on_demand_variant).should_track_inventory?).to eq(false)
    end

    it 'should track inventory when global and variant are on' do
      Spree::Config[:track_inventory_levels] = true

      expect(build(:variant).should_track_inventory?).to eq(true)
    end
  end

  describe "deleted_at scope" do
    before { variant.destroy && variant.reload }
    it "should have a price if deleted" do
      variant.label = 'food'
      expect(variant.label).to eq('food')
    end
  end

  context "check_stock" do

    let(:variant) { create(:variant) }

    it "calls check_stock in an after save" do
      expect(variant).to receive(:check_stock)
      variant.save
    end

    it "creates a job after save" do
      mock_object = double('stock_check_job', perform: true)
      expect(Spree::StockCheckJob).to receive(:new).with(variant).and_return(mock_object)
      expect(::Delayed::Job).to receive(:enqueue).with(mock_object, queue: 'stock_check', priority: 10)
      variant.send(:check_stock)
    end
  end


  describe "stock movements" do
    let!(:movement) { create(:stock_movement, stock_item: variant.stock_items.first) }

    it "builds out collection just fine through stock items" do
      expect(variant.stock_movements.to_a).not_to be_empty
    end
  end

  describe "in_stock scope" do
    it "returns all in stock variants" do
      in_stock_variant = create(:variant)
      out_of_stock_variant = create(:variant)

      in_stock_variant.update_column(:in_stock_cache, true)

      expect(Spree::Variant.in_stock).to eq [in_stock_variant]
    end
  end
end
