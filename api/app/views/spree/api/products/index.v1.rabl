object false
if @products.respond_to?(:num_pages)
  node(:count) { @products.count }
  node(:total_count) { @products.total_count }
  node(:current_page) { params[:page] ? params[:page].to_i : 1 }
  node(:pages) { @products.num_pages }
end
child(@products) do
  extends "spree/api/products/show"
end
