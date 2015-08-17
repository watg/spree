module Admin
  class ProductTabPresenter
    attr_reader :product

    def initialize(product)
      @product = product
    end

    def parts?
      product.kit? || product.normal?
    end
  end
end
