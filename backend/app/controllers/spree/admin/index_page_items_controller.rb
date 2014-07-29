module Spree
  module Admin
    class IndexPageItemsController < ResourceController
      belongs_to 'spree/index_page'

      def s3_callback
        item = @index_page.items.find(params[:id])
        image = Spree::IndexPageItemImage.where(viewable: item).first_or_create
        @outcome = UploadImageToS3Service.run(
          image: image,
          attachment_file_name: params[:filename],
          attachment_content_type: params[:filetype],
          attachment_file_size: params[:filesize],
          direct_upload_url: params[:image][:direct_upload_url]
        )
      end

      def location_after_save
        edit_admin_index_page_path(@index_page)
      end

      def location_after_destroy
        edit_admin_index_page_path(@index_page)
      end


    end
  end
end
