require "spec_helper"

describe ::Admin::PartImagePresenter, type: :presenter do
  let(:part_image) { ::PartImage.new }
  let!(:view_object) { double(link_to: "", image_tag: "") }
  subject { described_class.new(part_image, view_object, {}) }

  describe "#image_url" do
    context "image has not been processed" do
      it "returns upload url" do
        expect(part_image).to receive(:direct_upload_url)
        subject.image_url
      end
    end

    context "image has been processed" do
      let(:attachment) { double(url: "image_url") }

      before do
        allow(part_image).to receive(:processed?).and_return(true)
        allow(part_image).to receive(:attachment).and_return(attachment)
      end

      it "returns processed image url" do
        expect(part_image).to receive(:attachment)
        subject.image_url
      end
    end
  end
end
