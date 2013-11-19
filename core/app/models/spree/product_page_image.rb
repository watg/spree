module Spree
  class ProductPageImage < Image
    
    has_attached_file :attachment,
      :styles        => { large: "3200x520>", small: '250x250>' },
      :default_style => :large,
      :url           => "/spree/product_pages/:id/:style/:basename.:extension",
      :path          => ":rails_root/public/spree/product_pages/:id/:style/:basename.:extension",
      :convert_options =>  { :all => '-strip -auto-orient' }

    supports_s3 :attachment
    Spree::ProductPageImage.attachment_definitions[:attachment][:url] = Spree::Config[:attachment_url]
  end
end
