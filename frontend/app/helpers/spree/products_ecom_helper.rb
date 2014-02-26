module Spree
  module ProductsEcomHelper

    def has_variants?(product, opt_value)
      !product.variants_for_option_value(opt_value).blank?
    end

    def variant_has_option_value?(variant, opt_value)
      list = (variant ? variant.option_values : [])

      list.detect {|ov| ov.id == opt_value.id}
    end

    def first_image(variant)
      variant.images_including_targetted[0] if variant && !variant.images_including_targetted.blank?
    end
    
    def thumb_classes(image)
      if image.viewable.class == Spree::Variant
        ['vtmb', "tmb-#{image.viewable.id}"].join(' ')
      elsif image.viewable.class == Spree::VariantTarget
        ['vtmb', "tmb-#{image.viewable.variant_id}"].join(' ')
      end
    end

    def show_thumb(image, selected_variant)
      # (selected_variant.id == image.viewable.variant_id) - added so 
      # the old site can display all targetted images
      if selected_variant 
        if(image.viewable_type == 'Spree::Variant' && selected_variant.id == image.viewable_id) || 
          (image.viewable_type == 'Spree::VariantTarget' && selected_variant.id == image.viewable.variant_id) || 
          (image.viewable_type == 'Spree::VariantTarget' && selected_variant.product.master.id == image.viewable.variant_id)
          "display:list-item;"
        else
          (selected_variant.is_master? ?  "display:list-item;"  : "display:none;")
        end
      end
    end
  end
end
