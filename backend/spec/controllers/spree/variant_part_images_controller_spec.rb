require 'spec_helper'

describe Spree::Admin::VariantPartImagesController, type: :controller do
  stub_authorization!

  describe "#s3_callback" do

    it 'calls s3 upload service' do
      variant = mock_model(Spree::Variant)
      product = mock_model(Spree::Product)

      allow(variant).to receive(:id).and_return(1)
      allow(variant).to receive(:product).and_return(product)
      allow(Spree::Variant).to receive(:find).and_return(variant)
      image = "image"

      params = {
        format: "js",
        filename: 'foo',
        filetype: 'jpg',
        filesize: 2,
        part_image: {
          direct_upload_url: 'www.mysupercomputer.ninja'
        },
        variant_id: variant.id
      }

      expect(Spree::UploadImageToS3Service).to receive(:run)

      spree_post :s3_callback, params


    end
  end

  describe "#update" do
    let(:variant) { create(:base_variant) }

    it "calls s3 updater service" do
      image = mock_model(::PartImage)
      allow(image).to receive(:update_attributes).and_return(image)
      allow(image).to receive(:id).and_return(1)
      allow(image).to receive(:result).and_return(image)
      allow(::PartImage).to receive(:find).and_return(image)

      params = {
        format: "js",
        variant_id: variant.id,
        id: 1,
      }

      expect(Spree::UpdateImageService).to receive(:run!).and_return(image)

      spree_put :update, params
    end
  end

end