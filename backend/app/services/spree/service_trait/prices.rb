module Spree
  module ServiceTrait
    module Prices

      def update_prices(prices, variant)
        prices.each do |type, currency_values|
          currency_values.each do |currency,value|
            object = variant.price_for_type(type,currency)
            object.price = value.dup
            object.save! if object.changed? 
          end
        end
      end

      def validate_prices(prices)
        Spree::Config[:supported_currencies].split(',').each do |currency|
          validate_price(prices, :normal, currency)
          validate_price(prices, :part, currency)
        end
      end

      def validate_price(prices, type, currency)
        price = prices[type][currency]
        if price.nil?
          add_error(:variant, :price, "price not set for type: #{type}, currency: #{currency}")
        elsif Spree::LocalizedNumber.parse(price) <= 0
          add_error(:variant,
                    :price, "amount can not be <= 0 for type: #{type}, currency: #{currency}")
        end
      end
    end
  end
end
