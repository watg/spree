object false
node(:count) { @product_pages.count }
node(:total_count) { @product_pages.total_count }
node(:current_page) { params[:page] ? params[:page].to_i : 1 }
node(:per_page) { params[:per_page] || Kaminari.config.default_per_page }
node(:pages) { @product_pages.num_pages }

child(@product_pages => :products) do
  extends "spree/api/olapic/show"
end
