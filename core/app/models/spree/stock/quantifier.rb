module Spree
  module Stock
    class Quantifier

      class << self
        def new(variant)
          instance = (variant.kind_of?(Spree::Variant) ? variant : Spree::Variant.find(variant))
          klass_name = (has_parts?(instance) ? 'AssemblyQuantifier' : 'SimpleQuantifier')
          klass = "Spree::Stock::#{klass_name}".constantize

          klass.new(instance)
        end

        def has_parts?(variant)
          variant.product.can_have_parts?
        end
      end

    end
  end
end
