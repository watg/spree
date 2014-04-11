# A rule to limit a promotion based on product types in the order.
# Can require all or any of the product types to be present.
# Valid product types either come from assigned product type or are assingned directly to the rule.
module Spree
  class Promotion
    module Rules
      class ProductType < PromotionRule
        has_and_belongs_to_many :product_types, class_name: '::Spree::ProductType', join_table: 'spree_product_types_promotion_rules', foreign_key: 'promotion_rule_id'

        def applicable?(promotable)
          promotable.is_a?(Spree::Order)
        end

        # scope/association that is used to test eligibility
        def eligible_product_types
          product_types.pluck(:name)
        end

        def eligible?(order, options = {})
          return true if eligible_product_types.empty?
          order.products.any? {|p| eligible_product_types.include?(p.product_type) }
        end
      end
    end
  end
end
