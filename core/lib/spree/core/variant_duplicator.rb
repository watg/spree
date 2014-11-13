module Spree
  class VariantDuplicator
    attr_accessor :variant

    def initialize(variant)
      @variant = variant
    end

    def duplicate_prices
      variant.prices.map do |price|
        new_price = price.dup
        new_price.variant_id = nil
        new_price
      end
    end

  end
end
