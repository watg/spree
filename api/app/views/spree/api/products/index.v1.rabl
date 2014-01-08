object false
node(:count) { @products.count }
node(:total_count) { @products.total_count }
node(:current_page) { params[:page] ? params[:page].to_i : 1 }
node(:per_page) { params[:per_page] || Kaminari.config.default_per_page }
node(:pages) { @products.num_pages }
child(@products) do
  attributes :id, :name
  child :first_variant_or_master => :variant do
    attributes :sku
    
    child :images => :images do
      extends "spree/api/images/show"
    end
  end
end
