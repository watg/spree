module Order
  module ProductFilter
    def contains_kit?
      products.detect{ |p| p.product_type.kit? }
    end

    def contains_pattern?
      products.detect{ |p| p.product_type.pattern? }
    end
  end
end
