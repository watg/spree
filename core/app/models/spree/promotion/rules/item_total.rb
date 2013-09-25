# A rule to apply to an order greater than (or greater than or equal to)
# a specific amount
module Spree
  class Promotion
    module Rules
      class ItemTotal < PromotionRule
        preference :amount, :decimal, :default => 100.00
        preference :operator, :string, :default => '>'
        preference :currency, :string
        preference :zone_id,  :string, :default => nil # this is a string so we can set it as nil

        attr_accessible :preferred_amount
        attr_accessible :preferred_operator
        attr_accessible :preferred_currency
        attr_accessible :preferred_zone_id

        OPERATORS = ['gt', 'gte']

        def eligible?(order, options = {})
          item_total_ok?(order) && currency_ok?(order) && location_ok?(order)
        end

        def self.currencies
          Spree::Config.preferences[:supported_currencies].split(',')
        end


        private
        def item_total_ok?(order)
          order_total = order.line_items.map(&:amount).sum
          order_total.send(preferred_operator == 'gte' ? :>= : :>, BigDecimal.new(preferred_amount.to_s))
        end

        def currency_ok?(order)
          preferred_currency == order.currency
        end

        def location_ok?(order)
          if order.shipping_address && !preferred_zone_id.blank?
            Spree::Zone.find(preferred_zone_id).include? order.shipping_address
          else
            true
          end
        end

      end
    end
  end
end
