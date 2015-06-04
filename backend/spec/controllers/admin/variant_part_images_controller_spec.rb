require "spec_helper"

describe ::Admin::VariantPartImagesController, type: :controller do
  stub_authorization!

  describe "#s3_callback" do
    let(:variant) { mock_model(Spree::Variant) }
    let(:product) { mock_model(Spree::Product) }
    let(:image) { mock_model(::PartImage) }
    let(:params) do
      {
        format: "js",
        filename: "foo",
        filetype: "jpg",
        filesize: 2,
        part_image: {
          direct_upload_url: "www.mysupercomputer.ninja"
        },
        variant_id: variant.id
      }
    end

    before do
      allow(variant).to receive(:id).and_return(1)
      allow(variant).to receive(:product).and_return(product)
    end

    context "when variant has a part image present" do
      it "does not upload a new image" do
        allow(variant).to receive(:part_image).and_return(image)
        allow(Spree::Variant).to receive(:find).and_return(variant)

        expect(Spree::UploadImageToS3Service).to_not receive(:run)
        spree_post :s3_callback, params
      end
    end

    context "when an image does not have a part image present" do
      it "calls s3 upload service" do
        allow(variant).to receive(:part_image).and_return(nil)

        allow(Spree::Variant).to receive(:find).and_return(variant)
        expect(Spree::UploadImageToS3Service).to receive(:run)
        spree_post :s3_callback, params
      end
    end
  end
end
