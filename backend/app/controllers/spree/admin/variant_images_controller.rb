module Spree
  module Admin
    class VariantImagesController < ResourceController
      before_filter :load_data

      def s3_callback
        image = Image.new(viewable: @variant)
        @outcome = UploadImageToS3Service.run(
          image: image,
          params: params,
          partial: 'image'
        )
        render 'spree/admin/shared/s3_callback'
      end

      def update
        invoke_callbacks(:update, :before)
        outcome = Spree::UpdateImageService.run(
          image: Spree::Image.find(params[:id]),
          target_id: params[:target_id],
          variant_id: params[:variant_id]
        )
        if outcome.valid?
          invoke_callbacks(:update, :after)
          flash[:success] = flash_message_for(outcome.result, :successfully_updated)
          respond_with(outcome.result) do |format|
            format.html { redirect_to location_after_save }
            format.js   { render :layout => false }
          end
        else
          invoke_callbacks(:update, :fails)
          respond_with(outcome.errors.message_list)
        end
      end

      private

      def model_class
        Spree::Image
      end

      def location_after_destroy
        admin_variant_images_url(@variant)
      end

      def location_after_save
        admin_variant_images_url(@variant)
      end

      def collection_url(opts={})
        spree.admin_variant_images_url(opts)
      end

      def load_data
        @variant = Variant.find(params[:variant_id])
        @product = @variant.product
      end

    end
  end
end
