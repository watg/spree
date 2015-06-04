module Spree
  module Admin
    class ImagesController < ResourceController
      before_action :load_data

      create.before :set_viewable
      update.before :set_viewable

      def s3_callback
        image = Image.new(viewable: @product.master)
        @outcome = UploadImageToS3Service.run(
          image: image,
          params: params,
          partial: "image"
        )
        render "spree/admin/shared/s3_callback"
      end

      def update
        invoke_callbacks(:update, :before)
        outcome = Spree::UpdateImageService.run(
          params[:image].merge(
                               image: Spree::Image.find(params[:id]),
                               variant_id: @product.master.id
                              )
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

        def location_after_destroy
          admin_product_images_url(@product)
        end

        def location_after_save
          admin_product_images_url(@product)
        end


        def collection_url(opts={})
          spree.admin_product_images_url(opts)
        end


        def load_data
          @product = Product.friendly.find(params[:product_id])
          @variants = @product.variants.collect do |variant|
            [variant.sku_and_options_text, variant.id]
          end
          @variants.insert(0, [Spree.t(:all), @product.master.id])
        end

        def set_viewable
          @image.viewable_type = 'Spree::Variant'
          @image.viewable_id = params[:image][:viewable_id]
        end

    end
  end
end
