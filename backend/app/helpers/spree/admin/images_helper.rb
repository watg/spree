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

      def get_personalisation_id(image)
        if image.viewable_type == 'Spree::Personalisation'
          image.viewable_id
        else
          nil
        end
      end

      
    end
  end
end