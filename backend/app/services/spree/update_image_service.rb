module Spree
  class UpdateImageService < Mutations::Command

    required do
      model :image, class: 'Spree::Image'
    end

    optional do
      integer :variant_id
      string :target_id, empty: true
      string :alt
    end

    def execute
      if variant_id
        set_viewable
        image.update_attributes(viewable: @viewable, alt: alt)
      else
        image.update_attributes(alt: alt)
      end
      image
    end

    private

    def set_viewable
      if target_id.present?
        @viewable = Spree::Variant.find(variant_id).targets.where(target_id: target_id).first_or_create
      else
        @viewable = Spree::Variant.find(variant_id)
      end
    end



  end
end
