module Order
  module ProductFilter
    def contains_pattern_or_kit?
      contains_pattern? || contains_kit?
    end

    private

    def contains_pattern?
      products.detect { |p| p.marketing_type && p.marketing_type.name['pattern'] }
    end

    def contains_kit?
      products.detect { |p| p.product_type.name['kit'] }
    end
  end
end
