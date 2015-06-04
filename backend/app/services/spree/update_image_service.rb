module Spree
  class UpdateImageService < ActiveInteraction::Base

    interface :image, methods: %i[update_attributes]

    integer :variant_id, default: nil
    string :target_id, default: nil
    string :personalisation_id, default: nil
    string :activate_personalisation, default: nil
    string :alt, default: nil

    def execute
      if variant_id || personalisation_id
        image.update_attributes(viewable: set_viewable, alt: alt, target_id: target_id)
      else
        image.update_attributes(alt: alt)
      end
      image
    end

    private

    def set_viewable
      if personalisation_id.present? and activate_personalisation
        viewable = Spree::Personalisation.find(personalisation_id)
      else
        viewable = Spree::Variant.find(variant_id)
      end
      viewable
    end

  end
end
