object false
child(@suppliers => :suppliers) do
  extends 'spree/api/suppliers/show'
end
node(:count) { @suppliers.count }
node(:current_page) { params[:page] || 1 }
node(:pages) { @suppliers.num_pages }
