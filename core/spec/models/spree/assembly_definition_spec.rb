require 'spec_helper'

describe Spree::AssemblyDefinition do
  let(:assembly) { create(:variant) }
  let(:assembly_product) { assembly.product }
  let(:option_type) { create(:option_type)}

  subject { Spree::AssemblyDefinition.create(variant_id: assembly.id)}

  context "Stock and Option Values" do

    let(:variant_no_stock)  { create(:variant, option_values: [create(:option_value)], in_stock_cache: false ) }
    let(:part1) { Spree::AssemblyDefinitionPart.create(assembly_definition_id: subject.id, product_id: variant_no_stock.product_id, count: 3, displayable_option_type: option_type ) }

    let(:variant) { create(:variant, in_stock_cache: true) }
    let(:part2) { Spree::AssemblyDefinitionPart.create(assembly_definition_id: subject.id, product_id: variant.product_id, count: 1, displayable_option_type: option_type ) }

    before do
      Spree::AssemblyDefinitionVariant.create(assembly_definition_part_id: part1.id, variant_id: variant_no_stock.id)
      Spree::AssemblyDefinitionVariant.create(assembly_definition_part_id: part2.id, variant_id: variant.id)
    end

    its(:selected_variants_out_of_stock) { should eq( {part1.id => [variant_no_stock.id]} )}
    its(:selected_variants_out_of_stock_option_values) { should eq( {part1.id => [variant_no_stock.option_values.pluck(:id)] } )}

  end

  context "validate_main_part" do

    let(:assembly_definition) { create(:assembly_definition) }
    let(:part) { create(:assembly_definition_part, assembly_definition: assembly_definition) }

    context "no main part but assembled parts set" do

      before do
        assembly_definition.main_part = part
      end

      it "should provide an error" do
        assembly_definition.save
        expect(assembly_definition.errors.any?).to be_true
      end

    end

    context "no assmebled parts but main part set" do

      before do
        part.assembled = true
        part.save
        assembly_definition.reload
      end

      it "should provide an error" do
        assembly_definition.save
        expect(assembly_definition.errors.any?).to be_true
      end

    end

  end

  describe "set_assembly_product" do
    it "set assembly product before create" do
      ad = Spree::AssemblyDefinition.new(variant_id: assembly.id)
      expect(ad.assembly_product).to be_nil
      ad.save
      expect(ad.assembly_product).to_not be_nil
    end
  end

  describe "#images_for" do
    let(:target) { create(:target) }
    let(:target_2) { create(:target) }
    let!(:ad_images) { create_list(:assembly_definition_image, 1, viewable: subject, position: 2) }
    let!(:ad_target_images) { create_list(:assembly_definition_image, 1, viewable: subject, target: target, position: 1) }
    let!(:ad_target_images_2) { create_list(:assembly_definition_image, 1, viewable: subject, target: target_2, position: 1) }

    it "returns targeted only images" do
      expect(subject.images_for(target)).to eq( ad_target_images + ad_images )
    end

    it "returns non targeted images" do
      expect(subject.images_for(nil)).to eq( ad_images )
    end

  end

  describe "touch" do

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

end
