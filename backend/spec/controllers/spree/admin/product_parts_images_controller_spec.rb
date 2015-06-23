require "spec_helper"

module Spree
  module Admin
    describe ProductPartsImagesController do
      stub_authorization!
      render_views
      let!(:variant)       { create(:base_variant) }
      let(:product)       { variant.product }

      describe "#s3_callback" do
        let(:image) { mock_model(::ProductPartsImage) }
        let(:params) do
          {
            format: "js",
            filename: "foo",
            filetype: "jpg",
            filesize: 2,
            image: {
              direct_upload_url: "www.mysupercomputer.ninja"
            },
            product_id: product.slug
          }
        end
        let(:result) { double('result', image: image) }

        it "uploades an image" do
          expect(ProductPartsImage).to receive(:new).with(product: product) .and_return(image)

          expect(Spree::UploadImageToS3Service).to receive(:run).with(
            params: anything,
            partial: "image",
            image: image
          ).and_return(double('outcome', valid?: true, result: result))

          spree_post :s3_callback, params
          expect(flash[:error]).to be_nil
        end
      end

    end
  end
end
