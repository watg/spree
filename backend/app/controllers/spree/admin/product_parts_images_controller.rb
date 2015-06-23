module Spree
  module Admin
    class ProductPartsImagesController < ResourceController
      before_action :load_data

      def s3_callback
        image = ProductPartsImage.new(product: @product)
        @outcome = Spree::UploadImageToS3Service.run(
          image: image,
          params: params,
          partial: "image"
        )
      end

      private
      def load_data
        @product = Product.friendly.find(params[:product_id])
      end

      def model_class
        ::ProductPartsImage
      end

      def collection_url(opts = {})
        spree.admin_product_product_parts_image_url(params[:product_id], opts)
      end

    end
  end
end
