module Spree
  module ServiceTrait
    module Prices

      def update_prices(prices, variant)
        prices.each do |type, currency_values|
          currency_values.each do |currency,value|
            object = variant.price_for_type(type,currency)
            object.price = value 
            object.save if object.changed? 
            if object.errors.any?
              add_error(:variant, :price, "#{type}-#{currency}  price: #{object.errors.full_messages.join(', ')}")
            end
          end
        end
      end

    end
  end
end
