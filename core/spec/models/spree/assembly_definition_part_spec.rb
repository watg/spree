# encoding: utf-8
require 'spec_helper'

describe Spree::AssemblyDefinitionPart do

  let(:variant)  { create(:base_variant) }
  let(:assembly_product) { variant.product }
  let(:part)  { create(:base_product) }
  let(:assembly_definition) { create(:assembly_definition, variant: variant) }
  let(:colour)   { create(:option_type, name: 'colour', position: 2 )}
  subject { create(:assembly_definition_part, assembly_definition: assembly_definition, product: part, displayable_option_type: colour ) }

  context "Stock and Option Values" do

    let(:size)     { create(:option_type, name: 'size', presentation: 'Size', position: 1 )}
    let(:big)      { create(:option_value, name: 'big', presentation: 'Big', option_type: size, position: 0) }
    let(:small)    { create(:option_value, name: 'small', presentation: 'Small', option_type: size, position: 1) }

  #  let(:colour)   { create(:option_type, name: 'colour', position: 2 )}
    let(:pink)     { create(:option_value, name: 'pink', presentation: 'Pink', option_type: colour, position: 0) }
    let(:blue)     { create(:option_value, name: 'blue', presentation: 'Blue', option_type: colour, position: 1) }

    let(:language) { create(:option_type, name: 'language', presentation: 'Language', position: 3 )}
    let(:french)   { create(:option_value, name: 'french', presentation: 'French', option_type: language, position: 0) }
    let(:english)   { create(:option_value, name: 'english', presentation: 'English', option_type: language, position: 1) }


    let!(:variant_in_stock1)  { create(:variant_with_stock_items, product: product, option_values: [pink,small] ) }
    let!(:variant_in_stock2)  { create(:variant_with_stock_items, product: product, option_values: [pink,big] ) }
    let!(:variant_in_stock3)  { create(:variant_with_stock_items, product: product, option_values: [blue,small] ) }
    let!(:variant_in_stock4)  { create(:variant_with_stock_items, product: product, option_values: [blue,big] ) }
    let!(:variant_out_of_stock)  { create(:variant, product: product, option_values: [english] ) }
    let!(:variant_in_stock5)  { create(:variant_with_stock_items, product: product, option_values: [french] ) }


    let(:product)  { create(:base_product) }

    before do
      subject.variants = [ variant_in_stock1, variant_in_stock2, variant_in_stock3, variant_in_stock4, variant_out_of_stock ]
    end

    context "#option_values_in_stock" do
      it "should return option values" do
        expect(subject.option_values).to include(big,small,pink,blue)
      end
    end

    context "#variant_options_tree_for" do
      it "should return variant_options_tree_for" do
        tree = subject.variant_options_tree_for('USD')
        expect(tree["colour"]["pink"]["variant"]["in_stock"]).to_not be_nil
        expect(tree["colour"]["blue"]["variant"]["in_stock"]).to_not be_nil
        expect(tree["colour"]["pink"]["variant"]["in_stock"]).to_not be_nil
        expect(tree["colour"]["blue"]["variant"]).to_not be_nil
        expect(tree["language"]).to be_nil
      end
    end
  end

  context "set_assembly_product" do
    it "set assembly product before create" do
      adp = Spree::AssemblyDefinitionPart.new(assembly_definition_id: assembly_definition.id, product_id: part.id,  displayable_option_type: colour )
      expect(adp.assembly_product).to be_nil
      adp.save
      expect(adp.assembly_product).to_not be_nil
    end
  end

  context "touch" do

    before { Timecop.freeze }
    after { Timecop.return }

    it "touches assembly product after touch" do
      assembly_product.update_column(:updated_at, 1.day.ago)
      subject.touch
      expect(assembly_product.reload.updated_at).to be_within(1.seconds).of(Time.now)
    end

    it "touches assembly product after save" do
      assembly_product.update_column(:updated_at, 1.day.ago)
      subject.touch
      expect(assembly_product.reload.updated_at).to be_within(1.seconds).of(Time.now)
    end

  end

  context "when add all variants is set to true (default)" do

    it 'adds all available variants' do
      expect(subject.add_all_available_variants).to be_true
      expect(subject.assembly_definition_variants).to eq (2)

      # set up roughly 5 different variants - probs above
      # expect the variant count to be all the variants
    end

  end

  context "when add all variants is set to true" do

    it 'does not add all available variants' do
      subject.add_all_available_variants = false

      expect(subject.add_all_available_variants).to be_false
      expect(subject.assembly_definition_variants).to eq (2)
        # not sure about what to pop in here
        # when the amount of variants is set to false,
        # the number of variants = nil
    end
  end
end

