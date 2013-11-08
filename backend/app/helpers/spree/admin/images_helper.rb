module Spree
  module Admin
    module ImagesHelper
      def get_variant_id(image)
        if image.viewable_type == 'Spree::Variant'
          image.viewable_id
        elsif image.viewable_type == 'Spree::VariantTarget'
          image.variant_id
        end
      end
    end
  end
end