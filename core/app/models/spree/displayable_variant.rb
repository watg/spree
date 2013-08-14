module Spree
  class DisplayableVariant < ActiveRecord::Base
    belongs_to :variant
    belongs_to :taxon
    
    attr_accessible :product_id, :variant_id, :taxon_id

    class << self
      def by_product(product)
        where(product_id: product.id)
      end
    end
  end
end
