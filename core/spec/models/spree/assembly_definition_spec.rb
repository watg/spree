require "spec_helper"

describe Spree::AssemblyDefinition do
  let(:assembly) { create(:variant) }
  let(:assembly_product) { assembly.product }
  let(:part) { create(:base_product) }
  let(:option_type) { create(:option_type) }

  subject { described_class.create(variant_id: assembly.id) }

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
