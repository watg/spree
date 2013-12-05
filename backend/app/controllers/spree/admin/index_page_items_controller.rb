module Spree
  module Admin
    class IndexPageItemsController < Spree::Admin::BaseController
      before_filter :load_index_page

      def create
        @index_page.items.create!(item_params)
        redirect_to [:edit, :admin, @index_page]
      end

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

      def destroy
        item = @index_page.items.find(params[:id])
        item.destroy
        redirect_to [:edit, :admin, @index_page]
      end

      private

      def load_index_page
        @index_page = Spree::IndexPage.find(params[:index_page_id])
      end

      def item_params
        params.require(:index_page_item).permit(:title, :product_page_id, :variant_id)
      end
    end
  end
end
