module Spree
  module Admin
    class IndexPagesController < ResourceController
      before_filter :setup_new_index_page_item, :only => [:edit]

      def update_items_positions
        params[:positions].each do |id, index|
          IndexPageItem.where(:id => id).update_all(:position => index)
        end

        respond_to do |format|
          format.html { redirect_to admin_index_pages_url(params[:index_page_id]) }
          format.js  { render :text => 'Ok' }
        end
      end

      protected

        def location_after_save
          if @index_page.created_at == @index_page.updated_at
            edit_admin_index_page_url(@index_page)
          else
            admin_index_pages_url
          end
        end


      private
    
        def setup_new_index_page_item
          @index_page.items.new if @index_page.items.empty?
        end

   
    end
  end
end
