module Admin
  #  Presents Variant
  class VariantPresenter < Spree::BasePresenter
    presents :variant

    delegate :next, :previous, to: :variant
    delegate :link_to_with_icon, :admin_variant_part_images_url, to: :template

    def next_part_image_button
      link_to_with_icon("fa fa-arrow-right", Spree.t(:next),
                        admin_variant_part_images_url(variant.next), class: "button")
    end

    def previous_part_image_button
      link_to_with_icon("fa fa-arrow-left", Spree.t(:previous),
                        admin_variant_part_images_url(variant.previous), class: "button")
    end
  end
end
