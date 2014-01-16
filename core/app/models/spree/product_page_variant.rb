module Spree
  class ProductPageVariant < ActiveRecord::Base
    acts_as_paranoid

    belongs_to :product_page, touch: true
    belongs_to :variant
    belongs_to :target

    # We order by id as well, in case there is race condition which 
    # gives us 2 variants with the same position, otherwise this breaks 
    # pagination further up the stack
    default_scope { order(:position,:id) }
  end
end
