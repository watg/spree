module Spree
  module ServiceTrait
    module Prices

      def update_prices(prices, variant)
        prices.each do |type, currency_values|
          currency_values.each do |currency,value|
            object = variant.price_for_type(type,currency)
            object.price = value.dup
            object.save! if object.changed? 
            #if object.errors.any?
            #  add_error(:variant, :price, "#{type}-#{currency}  price: #{object.errors.full_messages.join(', ')}") 
            #end 
          end
        end
      end

      def validate_prices(prices)
        Spree::Config[:supported_currencies].split(',').each do |currency|
          p = prices[:normal][currency]
          if p.nil?
            add_error(:variant, :price, "price not set for type: normal, currency: #{currency}") 
          else
            if Spree::Price.parse_price(p) <= 0
              add_error(:variant, :price, "amount can not be <= 0 for currency: #{currency} and normal price")
            end
          end
        end
      end

    end
  end
end
