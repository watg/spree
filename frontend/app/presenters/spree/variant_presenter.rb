module Spree
  class VariantPresenter < BasePresenter
    presents :variant

    delegate :id, :name, :product, :in_sale?, to: :variant

    ### Memoized accessors ###

    def option_types_and_values
      @option_types_and_values ||= variant.option_types_and_values.to_json
    end

    def level
      @level ||= variant.product.property("level")
    end

    def displayable_suppliers
      @displayable_suppliers ||= variant.suppliers.displayable
    end

    ### Images ##

    def placeholder_image
      h.image_path("product-group/placeholder-470x600.gif")
    end

    def first_image
      @first_image ||= images.first
    end

    def first_image_url(style = :small)
      @first_image_url ||= {}
      return @first_image_url[style] if @first_image_url[style]
      image = first_image
      @first_image_url[style] = if image.present?
                                  image.attachment.url(style)
                                else
                                  h.image_path("product-group/placeholder-470x600.gif")
                                end
      @first_image_url[style]
    end

    def main_image_url
      style = is_mobile? ? :small : :product
      first_image_url(style)
    end

    def main_image_options
      options = { itemprop: "image" }
      if is_desktop?
        options.merge!(
          class: "zoomable",
          data: { zoomable: first_image_url(:original) }
        )
      end
      options
    end

    ### Prices ##

    def price
      @price ||= variant.price_normal_in(currency)
    end

    def price_in_subunit
      price.in_subunit
    end

    def price_html
      price.display_price.to_html
    end

    def sale_price
      @sale_price ||= variant.price_normal_sale_in(currency)
    end

    def sale_price_in_subunit
      sale_price.in_subunit
    end

    def sale_price_html
      sale_price.display_price.to_html
    end

    def currency_symbol
      price.currency_symbol
    end

    def normal_price_classes
      classes = if variant.in_sale?
                  ["normal-price", "price", "was"]
                else
                  ["normal-price", "price"]
                end
      classes << "unselected" if product.parts.any?
      classes.join(" ")
    end

    def displayable_supplier_nickname
      if displayable_suppliers.any?
        displayable_suppliers.map(&:nickname).to_sentence
      else
        "WATG"
      end
    end

    def sale_price_classes
      classes = if variant.in_sale?
                  ["sale-price", "price"]
                else
                  ["sale-price", "price", "hide"]
                end
      classes << "unselected" if product.parts.any?
      classes.join(" ")
    end

    private

    def images
      @images ||= begin
        images = variant.images_for(target)
        images = product.variant_images_for(target) if images.blank?
        images
      end
    end
  end
end
