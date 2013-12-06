module Spree
  module Admin
    class IndexPageItemsController < ResourceController

      def s3_callback
        item = @index_page.items.find(params[:id])
        callback_params = {
          attachment_file_name: params[:filename],
          attachment_content_type: params[:filetype],
          attachment_file_size: params[:filesize],
          direct_upload_url: params[:image][:direct_upload_url]
        }
        image = Spree::IndexPageItemImage.where(viewable: item).first_or_create
        @outcome = UploadImageToS3Service.run(callback_params, image: image)
      end

      def update_positions
        params[:positions].each do |id, index|
          IndexPageItem.where(:id => id).update_all(:position => index)
        end

        respond_to do |format|
          format.html { redirect_to location_after_save }
          format.js  { render :text => 'Ok' }
        end
      end

      def location_after_destroy
        edit_admin_index_page_path(@index_page)
      end


    end
  end
end
