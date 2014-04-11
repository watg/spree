# A rule to limit a promotion based on product groups in the order.
# Can require all or any of the product groups to be present.
# Valid product groups either come from assigned product group or are assingned directly to the rule.
module Spree
  class Promotion
    module Rules
      class ProductGroup < PromotionRule
        has_and_belongs_to_many :product_groups, class_name: '::Spree::ProductGroup', join_table: 'spree_product_groups_promotion_rules', foreign_key: 'promotion_rule_id'


        MATCH_POLICIES = %w(any all)
        preference :match_policy, :string, default: MATCH_POLICIES.first

        def applicable?(promotable)
          promotable.is_a?(Spree::Order)
        end

        # scope/association that is used to test eligibility
        def eligible_product_groups
          product_groups
        end

        def eligible?(order, options = {})
          return true if eligible_product_groups.empty?
          if preferred_match_policy == 'all'
            eligible_product_groups.all? {|p| order.product_groups.include?(p) }
          else
            order.product_groups.any? {|p| eligible_product_groups.include?(p) }
          end
        end

        def product_group_ids_string
          product_group_ids.join(',')
        end

        def product_group_ids_string=(s)
          self.product_group_ids = s.to_s.split(',').map(&:strip)
        end
      end
    end
  end
end
