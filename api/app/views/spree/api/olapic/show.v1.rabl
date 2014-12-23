object @suite
node(:productId) { |s| s.permalink }
node(:name) { |s| s.title }
node(:productUrl) do |s|
  spree.suite_url(s.permalink)
end
node(:stockImageUrl) do |s| 
  if s.image
    image_url(s.image.attachment.url)
  else
    image_url("/product-group/placeholder-470x600.gif")
  end
end
node(:category) { |s| s.target.name if s.target }
