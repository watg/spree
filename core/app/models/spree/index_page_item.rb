module Spree
  class IndexPageItem < ActiveRecord::Base
    acts_as_paranoid

    has_one :image, as: :viewable, dependent: :destroy, class_name: "Spree::IndexPageItemImage"
    accepts_nested_attributes_for :image, allow_destroy: true

    belongs_to :index_page, touch: true
    belongs_to :product_page
    belongs_to :variant

    # We order by id as well, in case there is race condition which 
    # gives us 2 variants with the same position, otherwise this breaks 
    # pagination further up the stack
    default_scope { order(:position,:id) }
    acts_as_list :scope => :index_page

    validates_presence_of :product_page
    
    LARGE_TOP = 1
    SMALL_BOTTOM = 2

    TEMPLATES = [
      { id: LARGE_TOP, name: "top left hand" },
      { id: SMALL_BOTTOM, name: "bottom centre" }
    ]

  end
end
