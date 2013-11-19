module Spree
  class ProductPageTabImage < Image
    
    has_attached_file :attachment,
      :styles        => { large: "3200x520>", small: '250x250>' },
      :default_style => :large,
      :url           => "/spree/product_page_tabs/:id/:style/:basename.:extension",
      :path          => ":rails_root/public/spree/product_page_tabs/:id/:style/:basename.:extension",
      :convert_options =>  { :all => '-strip -auto-orient' }

    
    # to do: delete the previous image from the file system
    def destroy_image!
      self.attachment.destroy
    end

  end
end
