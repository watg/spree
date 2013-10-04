module Spree
  module ServiceTrait
    module Prices

      def update_prices(prices, variant)
        prices.each do |type, currency_values|
          currency_values.each do |currency,value|
            object = variant.price_for_type(type,currency)
            object.price = value.dup
            object.save if object.changed? 
            if object.errors.any?
              add_error(:variant, :price, "#{type}-#{currency}  price: #{object.errors.full_messages.join(', ')}") 
            end 
          end
        end
      end

    # Not in use yet but maybe one day it will come in handy
    #  def validate_prices(prices_by_type, variant_in_sale_ids_set, variant_id )
    #    prices_by_type.each do |type, prices|
    #      prices.each do |currency,value|
    #        price = parse_price(value)
    #        if price < 0.01
    #          if type != SALE 
    #            variant = Spree::Variant.find(variant_id)
    #            add_error(:price, :range_mismatch, "variant: #{variant.options_text} price can not be less than 0.01" )
    #          elsif variant_in_sale_ids_set.include? variant_id.to_s
    #            variant = Spree::Variant.find(variant_id)
    #            add_error(:price, :range_mismatch, "variant: #{variant.options_text} price can not be less than 0.01" )
    #          end
    #        end
    #      end
    #    end
    #  end

    end
  end
end
