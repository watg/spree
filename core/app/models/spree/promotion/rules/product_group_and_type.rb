# A rule to limit a promotion based on product groups in the order.
# Can require all or any of the product groups to be present.
# Valid product groups either come from assigned product group or are assingned directly to the rule.
module Spree
  class Promotion
    module Rules
      class ProductGroupAndType < PromotionRule
        has_and_belongs_to_many :product_groups, class_name: '::Spree::ProductGroup', join_table: 'spree_product_groups_promotion_rules', foreign_key: 'promotion_rule_id'
        has_and_belongs_to_many :product_types, class_name: '::Spree::ProductType', join_table: 'spree_product_types_promotion_rules', foreign_key: 'promotion_rule_id'

        def applicable?(promotable)
          promotable.is_a?(Spree::Order)
        end

        # scope/association that is used to test eligibility
        def eligible?(order,options={})
          return true if eligible_product_groups.empty? and eligible_product_types.empty?

          selector = order.line_items.joins(:product)

          if eligible_product_types.any?
            selector = selector.where("spree_products.product_type in (?)", eligible_product_types)
          end
          if eligible_product_groups.any?
            selector = selector.where("spree_products.product_group_id in (?)", eligible_product_groups)
          end

          selector.any?
        end

        def product_group_ids_string
          product_group_ids.join(',')
        end

        def product_group_ids_string=(s)
          self.product_group_ids = s.to_s.split(',').map(&:strip)
        end

        private
        
        def eligible_product_groups
          product_groups.pluck(:id)
        end

        def eligible_product_types
          product_types.pluck(:name)
        end

      end
    end
  end
end
