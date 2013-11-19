module Spree
  module Admin
    class IndexPageItemsController < Spree::Admin::BaseController
      def destroy
        index_page_item = Spree::IndexPageItem.find(params[:id])
        index_page_item.destroy
        render :text => nil
      end
    end
  end
end
