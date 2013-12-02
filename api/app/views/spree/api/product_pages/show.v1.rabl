object @product_page
attributes *product_page_attributes

node("image_url") { |product_page|
  if !product_page.image.blank?
    product_page.image.attachment.url(:mini)
  end
}
