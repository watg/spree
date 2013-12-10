module Spree
  class ProductPageVariant < ActiveRecord::Base
    acts_as_paranoid

    belongs_to :product_page, touch: true
    belongs_to :variant
    belongs_to :target

    default_scope { order(:position) }
  end
end
