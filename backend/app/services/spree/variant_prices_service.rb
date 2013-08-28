module Spree
  class VariantPricesService < Mutations::Command 

    required do
      duck  :vp
      model :product, class: 'Spree::Product'
      array :variant_in_sale_ids
      array :supported_currencies
    end

    def execute
      inputs[:vp].each do |variant_id, prices_by_type|
        variant = Spree::Variant.find(variant_id)

        # Validate prices are not zero
        prices_by_type.each do |type, prices|
          prices.each do |currency,value|
            price = parse_price(value)
            if price < 0.01
              add_error(:price, :range_mismatch, 'price can not be less than 0.01' )
              return
            end
          end
        end


        prices_by_type.each do |type, prices|
          update_variant_prices(variant, type, prices, supported_currencies)
        end
      end

      update_variant_sale(product,variant_in_sale_ids)
    end

    private

    def if_variant_is_sale_price_can_not_be_zero
    end

    def price_can_not_be_zreo
    end


    def update_variant_sale(product, variant_ids)
      Spree::Variant.where(product_id: product.id).update_all(in_sale: false, updated_at: Time.now)
      Spree::Variant.where(id: variant_ids).update_all(in_sale: true, updated_at: Time.now)
      product.touch # this is here to invalidate the cache set on taxon through product 
    end
    
    def update_variant_prices(v, t, p, supported_currencies)
      supported_currencies.each do |currency|
        o = v.price_for_type(t,currency.iso_code)
        o.price = (p[currency.iso_code].blank? ? nil : p[currency.iso_code])
        o.save if o.changed?
        add_error(:variant, :price, "#{v.options_text} #{t} price: #{o.errors.full_messages.join(', ')}") if o.errors.any?
      end
    end

    # strips all non-price-like characters from the price, taking into account locale settings
    def parse_price(price)
      return price unless price.is_a?(String)

      separator, delimiter = I18n.t([:'number.currency.format.separator', :'number.currency.format.delimiter'])
      non_price_characters = /[^0-9\-#{separator}]/
      price.gsub!(non_price_characters, '') # strip everything else first
      price.gsub!(separator, '.') unless separator == '.' # then replace the locale-specific decimal separator with the standard separator if necessary

      price.to_d
    end

  end
end
