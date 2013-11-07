module Spree
  module Admin
    class ImagesController < ResourceController
      before_filter :load_data

      def s3_callback
        callback_params = {
          attachment_file_name: params[:filename], 
          attachment_content_type: params[:filetype], 
          attachment_file_size: params[:filesize],
          direct_upload_url: params[:image][:direct_upload_url],
          viewable_id: @product.master.id # the Variant ID
        }
        @outcome = Spree::UploadImageToS3Service.run(callback_params)
      end

      create.before :set_viewable
      update.before :set_viewable

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
            [variant.options_text, variant.id]
          end
          @variants.insert(0, [Spree.t(:all), @product.master.id])
        end

        def set_viewable
          if image[:target_id].blank?         
            image[:viewable_id] = image[:variant_id]
            image[:viewable_type] = 'Spree::Variant'
          else
            image[:viewable_id] = Variant.find(image[:variant_id]).targets.where(target_id: image[:target_id]).first_or_create.id
            image[:viewable_type] = 'Spree::VariantTarget'
          end

          image.except!(:target_id, :variant_id)
        end

        def image
          params[:image]
        end


    end
  end
end
