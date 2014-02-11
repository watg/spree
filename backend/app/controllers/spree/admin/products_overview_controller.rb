# this clas was inspired (heavily) from the mephisto admin architecture
module Spree
  module Admin
    class ProductsOverviewController < Spree::Admin::BaseController
      def index
        @products = Spree::Product.order("id").page(params[:page]).per(50)
      end

      def update
        params[:products].each do |product|
          if product[:update_flag]
            d { product }
            p = Spree::Product.find(product[:id])
            p.update_attributes(martin_type_id: product[:martin_type], product_group_id: product[:product_group])
          end
        end
        redirect_to action: "index", page: params[:page]
      end

    end
  end
end
