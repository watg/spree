module Spree
  module Admin
    class IndexPagesController < ResourceController

      def update_items_positions
        params[:positions].each do |id, index|
          IndexPageItem.where(:id => id).update_all(:position => index)
        end

        respond_to do |format|
          format.html { redirect_to location_after_save }
          format.js  { render :text => 'Ok' }
        end
      end

      def add_item
        @index_page = IndexPage.find params[:id]
        outcome = Spree::AddIndexPageItemService.run(item_id:   params[:item_id],
                                                     item_type: params[:item_type],
                                                     index_page: @index_page)
        respond_to do |format|
          format.html { redirect_to location_after_save }
          format.js  { render :text => 'Ok' }
        end
      end

      protected

      def location_after_save
        edit_admin_index_page_url(@index_page)
      end

    end
  end
end
