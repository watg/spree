module Spree
  class ProductPageTabImage < Image
    
    has_attached_file :attachment,
      :styles        => { large: "3200x520>", small: '250x250>' },
      :default_style => :large,
      :convert_options =>  { :all => '-strip -auto-orient' },
      :keep_old_files => false
      
  end
end
