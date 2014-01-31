module Spree
  module Admin
    class ImagesController < ResourceController
      before_filter :load_data

      create.before :set_viewable
      update.before :set_viewable

      def s3_callback
        callback_params = {
          attachment_file_name: params[:filename],
          attachment_content_type: params[:filetype],
          attachment_file_size: params[:filesize],
          direct_upload_url: params[:image][:direct_upload_url],
        }
        image = Image.new(viewable: Variant.find(@product.master))
        @outcome = UploadImageToS3Service.run(callback_params, image: image)
      end

      def update
        invoke_callbacks(:update, :before)
        outcome = Spree::UpdateImageService.run(params[:image], image: Spree::Image.find(params[:id]))
        if outcome.success?
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
          @product = Product.find_by_permalink(params[:product_id])
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
