object false
child(@stock_locations => :stock_locations) do
  extends 'spree/api/stock_locations/show'
end
if @stock_locations.respond_to?(:num_pages)
  node(:count) { @stock_locations.count }
  node(:current_page) { params[:page] || 1 }
  node(:pages) { @stock_locations.num_pages }
end
