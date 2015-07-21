module Spree
  module Promotable
    # Returns any eligible global shipping promotions based on a users
    # country and their currency, this is achieved by querying the promtions
    # for a given long running free shipping promotion
    class GlobalFreeShipping
      attr_reader :country_code, :currency

      # This is brittle but enough to get this working
      GLOBAL_FREE_SHIPPING_PROMOTION_ID = 127

      SHIPPING_PARTIALS = ["au", "ca", "ch", "de", "es", "fr", "gb", "nz", "us"]

      def initialize(country_code, currency)
        @country_code = country_code
        @currency = currency
      end

      Item = Struct.new(:amount, :eligible?)

      def eligible_promotion
        if promotion && minimum_spend
          Item.new(minimum_spend, true)
        else
          Item.new(0, false)
        end
      end

      private

      def promotion
        @promo ||= Spree::Promotion.find_by_id(
          GLOBAL_FREE_SHIPPING_PROMOTION_ID
        )
      end

      def conditions
        @conditions ||= begin
                    item_total_rule = promotion.rules.detect do |rule|
                      rule.type == 'Spree::Promotion::Rules::ItemTotal'
                    end
                      item_total_rule.preferred_attributes
                    end
      end

      def minimum_spend
        @minimum_spend ||= fetch_minimum_spend
      end

      # This is designed to return the first match, this is consistent with
      # the promotion code
      # TODO: refactor to use the same code as the promotion rule item_total
      # { "USD" => 120 }
      def fetch_minimum_spend
        conditions.each do |zone_id, currency_value|
          next unless user_zone_ids.include? zone_id.to_i
          value = currency_value[currency]
          return value["amount"].to_i if value && (value["enabled"] == "true")
        end
        nil
      end

      def user_zone_ids
        @user_zone_ids ||= begin
          country = Spree::Country.find_by(iso: country_code)
          members = Spree::ZoneMember.where(zoneable_id: country)
          members.map(&:zone_id)
        end
      end
    end
  end
end
