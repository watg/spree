require 'spec_helper'

describe Spree::Admin::VariantPartImagesController, type: :controller do
  stub_authorization!

  describe "#s3_callback" do

    context "when variant has a part image present" do
      let(:subject) { described_class }
      it "does not upload a new image" do

        variant = mock_model(Spree::Variant)
        product = mock_model(Spree::Product)
        image = mock_model(::PartImage)

        allow(variant).to receive(:id).and_return(1)
        allow(variant).to receive(:product).and_return(product)
        allow(variant).to receive(:part_image).and_return(image)
        allow(Spree::Variant).to receive(:find).and_return(variant)
        # require'pry';binding.pry

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

        expect(Spree::UploadImageToS3Service).to_not receive(:run)
        spree_post :s3_callback, params

      end
    end

    context "when an image does not have a part image present" do
      it 'calls s3 upload service' do
        variant = mock_model(Spree::Variant)
        product = mock_model(Spree::Product)

        allow(variant).to receive(:id).and_return(1)
        allow(variant).to receive(:product).and_return(product)
        allow(variant).to receive(:part_image).and_return(nil)

        allow(Spree::Variant).to receive(:find).and_return(variant)

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
  end
end
