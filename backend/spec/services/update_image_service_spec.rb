require 'spec_helper'

describe Spree::UpdateImageService do
  let(:base_variant) { create(:base_variant) }
  let(:image) { create(:image, viewable: base_variant) }
  let(:target) { create(:target) }
  let(:personalisation) { create(:personalisation) }

  context "#run" do
    let(:subject) { Spree::UpdateImageService }

    it "updates the alt attribute" do
      image_params = { alt: "holaa" }
      result = subject.run(image_params, image: image)

      expect(result).to be_success
      expect(image.reload.alt).to eq("holaa")
    end

    it "sets the viewable_type to Variant when personalisation_id is not present" do
      image_params = { variant_id: image.viewable.id, activate_personalisation: 123 }
      result = subject.run(image_params, image: image)

      expect(result).to be_success
      expect(image.reload.viewable_type).to eq("Spree::Variant")
      expect(image.reload.viewable_id).to eq(base_variant.id)
    end

    it "sets the viewable_type to Variant when activate_personalisation is not present" do
      image_params = { variant_id: image.viewable.id, personalisation_id: 12 }
      result = subject.run(image_params, image: image)

      expect(result).to be_success
      expect(image.reload.viewable_type).to eq("Spree::Variant")
      expect(image.reload.viewable_id).to eq(base_variant.id)
    end

    it "sets the viewable_type to Personalisation when personalisation_id and activate_personalsiation is present" do
      image_params = { personalisation_id: personalisation.id, activate_personalisation: 123 }
      result = subject.run(image_params, image: image)

      expect(result).to be_success
      expect(image.reload.viewable_type).to eq("Spree::Personalisation")
      expect(image.reload.viewable_id).to eq(personalisation.id)
    end

    it "sets the viewable_type to VariantTarget when target_id is present" do
      image_params = { variant_id: image.viewable.id, target_id: target.id }
      result = subject.run(image_params, image: image)

      expect(result).to be_success
      expect(image.reload.viewable_type).to eq("Spree::VariantTarget")
      expect(image.reload.viewable_id).to eq(base_variant.variant_targets.first.id)
    end

    it "sets the viewable_type to Variant when target_id is not present" do
      image_params = { variant_id: image.viewable.id, target_id: "" }
      result = subject.run(image_params, image: image)

      expect(result).to be_success
      expect(image.reload.viewable_type).to eq("Spree::Variant")
      expect(image.reload.viewable_id).to eq(base_variant.id)
    end



  end
end
