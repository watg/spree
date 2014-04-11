# A rule to apply to an order greater than (or greater than or equal to)
# a specific amount
module Spree
  class Promotion
    module Rules
      class ItemTotal < PromotionRule

        preference :_attributes, :string,  :default => "{}"

        def applicable?(promotable)
          promotable.is_a?(Spree::Order)
        end

        def eligible?(order, options = {})

          hash = JSON.parse get_preference(:_attributes)
          hash.each do |zone_id,currency_amount_enabled|

            currency_amount_enabled.each do |currency,amount_enabled|

              if order.currency == currency && amount_enabled['enabled'] == "true"

                order_total = order.line_items.map(&:amount).sum
                if order_total.send(:>=, BigDecimal.new(amount_enabled['amount'].to_s))

                  # If everything else is good but address as not been defined 
                  # then return false
                  if order.shipping_address
                    if Spree::Zone.find(zone_id).include? order.shipping_address
                      return true
                    end
                  else
                    return false
                  end

                end

              end

            end

          end
          return false
        end

        def self.currencies
          Spree::Config.preferences[:supported_currencies].split(',')
        end

        def preferred_attributes
          hash = JSON.parse get_preference(:_attributes)
          Spree::Zone.order(:name).each do |preferred_zone|
            Spree::Promotion::Rules::ItemTotal.currencies.each do |preferred_currency|
              preferred_zone_id = preferred_zone.id.to_s
              hash[preferred_zone_id] ||= {}
              hash[preferred_zone_id][preferred_currency] ||= {}
              hash[preferred_zone_id][preferred_currency]['amount'] ||= 0
              hash[preferred_zone_id][preferred_currency]['enabled'] ||= false
            end
          end
          hash
        end

        def preferred_attributes=(hash)
          set_preference(:_attributes, hash.to_json.to_s)
          save
        end

      end
    end
  end
end
