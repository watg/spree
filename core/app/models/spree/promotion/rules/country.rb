module Spree
  class Promotion
    module Rules
      class Country < PromotionRule
        has_and_belongs_to_many :countries, class_name: '::Spree::Country', join_table: 'spree_countries_promotion_rules', foreign_key: 'promotion_rule_id'
        
        def applicable?(promotable)
          promotable.is_a?(Spree::Order)
        end

        def eligible_country_codes
          countries.pluck(:iso)
        end

        def eligible?(order, options = {})
          return true if eligible_country_codes.empty?

          eligible_country_codes.include? Geocoder.search(order.last_ip_address).first.try(:country_code)
        end

      end
    end
  end
end
