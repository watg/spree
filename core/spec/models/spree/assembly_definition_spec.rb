require "spec_helper"

describe Spree::AssemblyDefinition do
  let(:assembly) { create(:variant) }
  let(:assembly_product) { assembly.product }
  let(:part) { create(:base_product) }
  let(:option_type) { create(:option_type) }

  subject { described_class.create(variant_id: assembly.id) }

  context "Stock and Option Values" do
    let(:variant_no_stock) do
      create(:variant, product: part, option_values: [create(:option_value)], in_stock_cache: false)
    end
    let(:product_part1) do
      Spree::AssemblyDefinitionPart.create(assembly_definition_id: subject.id,
                                           product: assembly_product,
                                           count: 3,
                                           part: part,
                                           displayable_option_type: option_type)
    end

    let(:variant) { create(:variant, in_stock_cache: true) }
    let(:product_part2) do
      Spree::AssemblyDefinitionPart.create(assembly_definition_id: subject.id,
                                           product: assembly_product,
                                           count: 1,
                                           part: part,
                                           displayable_option_type: option_type)
    end

    before do
      Spree::AssemblyDefinitionVariant.create(assembly_definition_part_id: product_part1.id,
                                              variant_id: variant_no_stock.id)
      Spree::AssemblyDefinitionVariant.create(assembly_definition_part_id: product_part2.id,
                                              variant_id: variant.id)
    end

    its(:selected_variants_out_of_stock) { should eq(product_part1.id => [variant_no_stock.id]) }
    its(:selected_variants_out_of_stock_option_values) do
    end
  end

  describe "set_assembly_product" do
    it "set assembly product before create" do
      ad = described_class.new(variant_id: assembly.id)
      expect(ad.assembly_product).to be_nil
      ad.save
      expect(ad.assembly_product).to_not be_nil
    end
  end

  describe "#images_for" do
    let(:target) { create(:target) }
    let(:target_2) { create(:target) }
    let!(:ad_images) { create_list(:assembly_definition_image, 1, viewable: subject, position: 2) }
    let!(:ad_target_images) do
      create_list(:assembly_definition_image, 1, viewable: subject, target: target, position: 1)
    end
    let!(:ad_target_images_2) do
      create_list(:assembly_definition_image, 1, viewable: subject, target: target_2, position: 1)
    end

    it "returns targeted only images" do
      expect(subject.images_for(target)).to eq(ad_target_images + ad_images)
    end

    it "returns non targeted images" do
      expect(subject.images_for(nil)).to eq(ad_images)
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
