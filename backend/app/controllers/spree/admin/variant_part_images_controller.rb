module Spree
  module Admin
    class VariantPartImagesController < ResourceController
      before_filter :load_data

      def s3_callback
        if @variant.part_image.blank?
          trigger_image_upload
        else
          render 'upload_error.js.erb'
        end
      end

      private

      def trigger_image_upload
        image = PartImage.new(variant: @variant)
          @outcome = Spree::UploadImageToS3Service.run(
            image: image,
            params: params,
            partial: 'part_image'
          )

        render 'spree/admin/shared/s3_callback'
      end

      def model_class
        ::PartImage
      end

      def location_after_destroy
        admin_variant_part_images_url(@variant)
      end

      def location_after_save
        admin_variant_part_images_url(@variant)
      end

      def collection_url(opts={})
        spree.admin_variant_part_images_url(opts)
      end

      def load_data
        @variant = Variant.find(params[:variant_id])
        @product = @variant.product
      end

    end
  end
end
