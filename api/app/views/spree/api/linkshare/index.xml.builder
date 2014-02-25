#
# variants: array of decorated variant with target
#
atom_feed("xmlns:g" => "http://base.google.com/ns/1.0",
          "xmlns:c" => "http://base.google.com/cns/1.0") do |feed|

  feed.title("Wool And The Gang")
  feed.updated(@variants[0].updated_at) if @variants.length > 0
  feed.link(spree.api_linkshare_index_path)
  feed.author do |author|
    author.name("Wool And The Gang")
  end

  @variants.each do |variant|
    feed.entry(variant, url: variant.product_page_url) do |entry|
      entry.title(variant.name)
      entry.id(variant.number)
#      entry.link(variant.product_page_url)
      entry.summary(variant.product.description)
      entry.updated(variant.updated_at)
      
      variant.images.each_with_index do |image, idx|
        entry.tag!((idx == 0 ? 'g:image_link' : 'g:additional_image_link'), image.attachment.url)
      end

      entry.tag!("g:price", variant.price_with_currency)
      entry.tag!("g:condition", "new")
      entry.tag!("g:availability", "in stock")
      entry.tag!("g:gender", variant.target)

      variant.color_and_size_option_values do |option|
        entry.tag!("g:#{option[0]}", option[1])
      end

      if variant.product.respond_to?(:product_type) && variant.product.product_type.respond_to?(:name)
        entry.tag!("g:google_product_category", variant.product.category)
        entry.tag!("g:product_type", variant.product.product_type.name)
      else
        entry.tag!("g:product_type", variant.product.product_type)
      end
    end
  end

end
