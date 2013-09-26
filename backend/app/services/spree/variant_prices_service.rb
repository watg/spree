module Spree
  class VariantPricesService < Mutations::Command 

    NORMAL = 'normal'
    SALE   = 'normal_sale'
    PART   = 'part'

    required do
      duck  :vp
      model :product, class: 'Spree::Product'
      array :variant_in_sale_ids
      array :supported_currencies
    end

    # TODO:
    # only do the validation for it being greater than 0 for the master

    def execute
      variant_in_sale_ids_set = variant_in_sale_ids.to_set

      # Validate prices are not zero when sales are enabled
      inputs[:vp].each do |variant_id, prices_by_type|
        validate_prices(prices_by_type, variant_in_sale_ids_set, variant_id) 
      end

      return if has_errors?

      inputs[:vp].each do |variant_id, prices_by_type|
        variant = Spree::Variant.find(variant_id)

        prices_by_type.each do |type, prices|
          update_variant_prices(variant, type, prices, supported_currencies)
        end
      end

      update_variant_sale(product,variant_in_sale_ids)
    end

    private

    def validate_prices(prices_by_type, variant_in_sale_ids_set, variant_id )
      prices_by_type.each do |type, prices|
        prices.each do |currency,value|
          price = parse_price(value)
          if price < 0.01
            if type != SALE 
              add_error(:price, :range_mismatch, 'price can not be less than 0.01' )
            elsif variant_in_sale_ids_set.include? variant_id.to_s
              add_error(:price, :range_mismatch, 'price can not be less than 0.01' )
            end
          end
        end
      end
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
