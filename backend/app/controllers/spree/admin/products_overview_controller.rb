# this clas was inspired (heavily) from the mephisto admin architecture
module Spree
  module Admin
    class ProductsOverviewController < Spree::Admin::BaseController
      def index
        if params[:name_cont]
          params[:name_cont] = '%' + params[:name_cont] + '%'
          @products = Spree::Product.where("spree_products.name ILIKE ?", params[:name_cont]).order("id").page(params[:page]).per( 50 )
        else
          @products = Spree::Product.order("id").page(params[:page]).per( 50 )
        end
      end

      def update
        params[:products].each do |product|
          if product[:update_flag]
            p = Spree::Product.find(product[:id])
            p.update_attributes(martin_type_id: product[:martin_type], product_group_id: product[:product_group])
          end
        end
        redirect_to action: "index", page: params[:page], name_cont: params[:name_cont]
      end

    end
  end
end
