module Api
  module Dashboard
    module Office
      # returns the last bought product formatted object for dashboard api
      class FormatLastBoughtProduct
        def initialize(valid_orders = nil)
          valid_orders ||= Spree::Order.complete.not_cancelled
          @orders = valid_orders
        end

        def run
          return false unless @orders.any?
          last_variant = @orders.last.variants.last
          last_product = last_variant.product
          variant_image_url = last_variant.images.first.attachment.url if last_variant.images.any?
          {
            name: last_product.name,
            marketing_type: last_product.marketing_type.title,
            image_url: variant_image_url
          }
        end
      end
    end
  end
end