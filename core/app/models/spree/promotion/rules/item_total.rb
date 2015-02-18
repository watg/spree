# A rule to apply to an order greater than (or greater than or equal to)
# a specific amount
module Spree
  class Promotion
    module Rules
      class ItemTotal < PromotionRule

        preference :attributes, :hash, default: {}

        def initialize(params={})
          params[:preferred_attributes] ||= default_data
          super(params)
        end

        def applicable?(promotable)
          promotable.is_a?(Spree::Order)
        end

        def eligible?(order, options = {})

          hash = preferred_attributes
          hash.each do |zone_id,currency_amount_enabled|

            currency_amount_enabled.each do |currency,amount_enabled|

              if order.currency == currency && amount_enabled['enabled'] == "true"

                order_total = order.item_total
                if order_total.send(:>=, BigDecimal.new(amount_enabled['amount'].to_s))

                  # If everything else is good but address as not been defined 
                  # then return true
                  if order.shipping_address
                    if Spree::Zone.find(zone_id).include? order.shipping_address
                      return true
                    end
                  else
                    return true
                  end

                end

              end

            end

          end
          return false
        end

        private
        def default_data
          hash = {}
          Spree::Zone.order(:name).each do |zone|
            Spree::Config[:supported_currencies].split(',').each do |currency|
              zone_id = zone.id.to_s
              hash[zone_id] ||= {}
              hash[zone_id][currency] ||= {}
              hash[zone_id][currency]['amount'] ||= 0
              hash[zone_id][currency]['enabled'] ||= false
            end
          end
          hash
        end

      end
    end
  end
end
