module Spree
  class UpdateImageService < Mutations::Command

    required do
      model :image, class: 'Spree::Image'
    end

    optional do
      integer :variant_id
      string :target_id, empty: true
      string :personalisation_id, empty: true
      string :activate_personalisation, empty: true
      string :alt
    end

    def execute
      if variant_id || personalisation_id
        image.update_attributes(viewable: set_viewable, alt: alt)
      else
        image.update_attributes(alt: alt)
      end
      image
    end

    private

    def set_viewable
      if personalisation_id.present? and activate_personalisation
        viewable = Spree::Personalisation.find(personalisation_id)
      elsif target_id.present?
        viewable = Spree::Variant.find(variant_id).variant_targets.where(target_id: target_id).first_or_create
      else
        viewable = Spree::Variant.find(variant_id)
      end
      viewable
    end

  end
end
