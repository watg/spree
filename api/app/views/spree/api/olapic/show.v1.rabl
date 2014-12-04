object @product_page
node(:productId) { |pp| pp.permalink }
node(:name) { |pp| pp.name }
node(:productUrl) do |pp|
  spree.product_page_url(pp.permalink)
end
node(:stockImageUrl) { |pp| image_url(pp.banner_url) }
node(:category) { |pp| pp.target.name if pp.target }
