module Spree
  module Admin
    module IndexPageHelper

      def first_image_url(item)
        if item.class == Spree::ProductPage && item.image
          item.image.attachment.url(:small)
        elsif item.class == Spree::Product && item.variant_images.any?
          item.variant_images.first.attachment.url(:mini)
        elsif item.class == Spree::Variant && item.images.any?
          item.images.first.attachment.url(:mini)
        else
          "noimage/small.png"
        end
      end

      def link_to_edit_item(item)
        if item.is_a?(Spree::Variant)
          url_for([:edit, :admin, item.product, item])
        else
          url_for([:edit, :admin, item])
        end
      end
    end
  end
end
