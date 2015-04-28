module Spree
  class Promotion
    module Actions
      class FreeShipping < Spree::PromotionAction
        has_and_belongs_to_many :shipping_methods, class_name: '::Spree::ShippingMethod', join_table: 'spree_shipping_methods_promotion_actions', foreign_key: 'promotion_action_id'

        def perform(payload={})
          order = payload[:order]
          results = order.shipments.map do |shipment|
            shipment.shipping_rates.map do |rate|
              next if promotion_credit_exists?(rate)
              next if shipping_rate_invalid?(rate)
              rate.adjustments.create!(
                order: shipment.order,
                amount: compute_amount(rate),
                source: self,
                label: label
              )
              true
            end
          end
          # Did we actually end up applying any adjustments?
          # If so, then this action should be classed as 'successful'
          results.flatten.any? { |r| r == true }
        end

        def label
          "#{Spree.t(:promotion)} (#{promotion.name})"
        end

        def compute_amount(adjustable)
          adjustable.cost * -1
        end

        private

        def promotion_credit_exists?(adjustable)
          adjustable.adjustments.where(source_id: self.id).exists?
        end

        def shipping_rate_invalid?(rate)
          !shipping_methods.include?(rate.shipping_method)
        end

      end
    end
  end
end
