module Spree
  module Admin
    class ProductPagesController < ResourceController

      def update
        outcome = Spree::UpdateProductPageService.run(product_page: @object, details: params[:product_page], tabs: params[:tabs])
        if outcome.success?
          update_success(@object)
        else
          update_failed(@object, outcome.errors.message_list.join(", "))
        end
      end

      def s3_callback
        callback_params = {
          attachment_file_name: params[:filename],
          attachment_content_type: params[:filetype],
          attachment_file_size: params[:filesize],
          direct_upload_url: params[:image][:direct_upload_url]
        }
        if params[:tab_id]
          tab = ProductPageTab.find params[:tab_id]
          image = ProductPageTabImage.where(viewable: tab).first_or_create
        else
          image = ProductPageImage.where(viewable: @object).first_or_create
        end

        @outcome = UploadImageToS3Service.run(callback_params, image: image)
      end

      protected
      def find_resource
        ProductPage.find_by_id(params[:id])
      end

      def update_success(product_page)
        flash[:success] = flash_message_for(product_page, :successfully_updated)

        respond_with(product_page) do |format|
          format.html { redirect_to spree.edit_admin_product_page_url(product_page) }
          format.js   { render :layout => false }
        end
      end

      def update_failed(product_page, error)
        flash[:error] = "Could not update product page #{product_page.name} -- #{error}"
        respond_with(product_page) do |format|
          format.html { redirect_to edit_admin_product_page_url(product_page) }
          format.js   { render :layout => false }
        end
      end

      def location_after_save
        edit_admin_product_page_url(@product_page)
      end

      def collection
        return @collection if @collection.present?
        params[:q] ||= {}
        params[:q][:s] ||= "name asc"
        @collection = super
        # @search needs to be defined as this is passed to search_form_for
        @search = @collection.ransack(params[:q])
        @collection = @search.result.
          page(params[:page]).
          per( 15 )
        @collection
      end

    end
  end
end
