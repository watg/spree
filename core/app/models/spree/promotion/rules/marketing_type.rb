# A rule to limit a promotion based on product types in the order.
# Can require all or any of the product types to be present.
# Valid product types either come from assigned product type or are assingned directly to the rule.
module Spree
  class Promotion
    module Rules
      class MarketingType < PromotionRule
        has_and_belongs_to_many :marketing_types, class_name: '::Spree::MarketingType', join_table: 'spree_marketing_types_promotion_rules', foreign_key: 'promotion_rule_id'

        def applicable?(promotable)
          promotable.is_a?(Spree::Order)
        end

        def eligible?(order, options = {})
          return true if marketing_types.empty?
          order.products.any? {|p| marketing_types.include?(p.marketing_type) }
        end
      end
    end
  end
end
