# A rule to limit a promotion based on product types in the order.
# Can require all or any of the product types to be present.
# Valid product types either come from assigned product type or are assingned directly to the rule.
module Spree
  class Promotion
    module Rules
      class ProductType < PromotionRule
        has_and_belongs_to_many :product_types, class_name: '::Spree::ProductType', join_table: 'spree_product_types_promotion_rules', foreign_key: 'promotion_rule_id'
        validate :only_one_promotion_per_product_type

        # scope/association that is used to test eligibility
        def eligible_product_types
          product_types.pluck(:name)
        end

        def eligible?(order, options = {})
          return true if eligible_product_types.empty?
          order.products.any? {|p| eligible_product_types.include?(p.product_type) }
        end

        # def product_type_ids_string
        #   product_type_ids.join(',')
        # end

        # def product_type_ids_string=(s)
        #   self.product_type_ids = s.to_s.split(',').map(&:strip)
        # end

        private

          def only_one_promotion_per_product_type
            if Spree::Promotion::Rules::ProductType.all.map(&:product_types).flatten.uniq!
              errors[:base] << "You can't create two promotions for the same product type"
            end
          end
      end
    end
  end
end