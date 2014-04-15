module Spree
  class ProductPageImage < Image
    
    has_attached_file :attachment,
      :styles        => { large: "3200x520>", small: '310x396>', mini: '150x150>' },
      :default_style => :large,
      :url           => "/spree/product_pages/:id/:style/:basename.:extension",
      :path          => ":rails_root/public/spree/product_pages/:id/:style/:basename.:extension",
      :convert_options =>  { :all => '-strip -auto-orient' }


  end
end
