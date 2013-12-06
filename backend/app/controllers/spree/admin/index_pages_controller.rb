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

      protected

      def location_after_save
        edit_admin_index_page_url(@index_page)
      end

    end
  end
end
