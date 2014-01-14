# A rule to limit a promotion based on product types in the order.
# Can require any of the product types to be present.
module Spree
  class Promotion
    module Rules
      class ProductType < PromotionRule
        has_many :product_types_promotion_rules, foreign_key: 'promotion_rule_id'
        validate :only_one_promotion_per_product_type

        # scope/association that is used to test eligibility
        def eligible_product_types
          product_type_promotions.pluck(:product_type)
        end

        def eligible?(order, options = {})
          return true if eligible_product_types.empty?
          order.products.any? {|p| eligible_product_types.include?(p.product_type) }
        end

        def product_ids_string
          Spree::Product.types.join(',')
        end

        def product_ids_string=(s)
          self.product_ids = s.to_s.split(',').map(&:strip)
        end

        private

          def only_one_promotion_per_product_type
            if Spree::Promotion::Rules::ProductType.all.map(&:product_types_promotion_rules).flatten.uniq!
              errors[:base] << "You can't create two promotions for the same product type"
            end
          end
      end
    end
  end
end
