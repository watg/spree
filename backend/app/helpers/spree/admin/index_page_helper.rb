module Spree
  module Admin
    module IndexPageHelper
      
      def first_image_url(item)
        if item.class == Spree::ProductPage
          item.image.attachment.url(:small)
        elsif item.class == Spree::Product
          item.variant_images.first.attachment.url(:mini)
        elsif item.class == Spree::Variant
          item.images.first.attachment.url(:mini)
        else
          "noimage/small.png"
        end
      end
    
    end
  end
end
