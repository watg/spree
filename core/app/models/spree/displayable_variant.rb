module Spree
  class DisplayableVariant < ActiveRecord::Base
    belongs_to :variant, touch: true
    belongs_to :taxon, touch: true
    belongs_to :product, touch: true
    
    #attr_accessible :product_id, :variant_id, :taxon_id

    class << self
      def by_product(product)
        where(product_id: product.id)
      end
    end
  end
end
