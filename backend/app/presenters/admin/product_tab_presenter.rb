module Admin
  class ProductTabPresenter
    attr_reader :product

    def initialize(product)
      @product = product
    end

    def parts?
      kit? || ready_to_wear?
    end

    private

    def kit?
      product.product_type.kit?
    end

    def ready_to_wear?
      Features.product_parts
    end
  end
end
