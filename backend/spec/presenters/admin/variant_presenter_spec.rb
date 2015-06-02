require "spec_helper"

describe ::Admin::VariantPresenter, type: :presenter do
  let(:variant) { create(:base_variant) }
  let!(:view_object) { double(link_to_with_icon: "", admin_variant_part_images_url: "") }
  subject { described_class.new(variant, view_object, {}) }

  describe "#next_part_image_button" do
    it "returns a link" do
      expect(view_object).to receive(:link_to_with_icon)
      expect(view_object).to receive(:admin_variant_part_images_url)
      subject.next_part_image_button
    end
  end

  describe "#previous_part_image_button" do
    it "returns a link" do
      expect(view_object).to receive(:link_to_with_icon)
      expect(view_object).to receive(:admin_variant_part_images_url)
      subject.previous_part_image_button
    end
  end
end
