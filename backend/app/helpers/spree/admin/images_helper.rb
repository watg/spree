module Spree
  module Admin
    module ImagesHelper
      def get_variant_id(image)
        if viewable_type == 'Spree::Variant'
          image.viewable_id
        elsif viewable_type == 'Spree::VariantTarget'
          image.variant_id
        end
      end
    end
  end
end