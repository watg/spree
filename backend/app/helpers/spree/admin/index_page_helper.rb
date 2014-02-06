module Spree
  module Admin
    module IndexPageHelper
      include CdnHelper

      def first_image_url(item)
        if item.class == Spree::ProductPage && item.image
          item.image.attachment.url(:small)
        elsif item.class == Spree::Product && item.variant_images.any?
          item.variant_images.first.attachment.url(:mini)
        elsif item.class == Spree::Variant && item.images.any?
          item.images.first.attachment.url(:mini)
        else
          cdn_url("noimage/small.png")
        end
      end

      def item_name(item)
        item.class.name.demodulize.titleize
      end

      def item_class(item)
        item.class.name.demodulize.underscore.dasherize
      end
    end
  end
end
