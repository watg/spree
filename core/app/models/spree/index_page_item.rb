module Spree
  class IndexPageItem < ActiveRecord::Base
    acts_as_paranoid

    delegate :name, to: :item
    
    belongs_to :item, polymorphic: true
    belongs_to :index_page
    belongs_to :target

    default_scope { order('position') }
    acts_as_list :scope => :index_page
    
    validates_uniqueness_of :index_page, :scope => [:item_id, :item_type], :message => :already_linked
    
    LARGE_TOP = 1
    SMALL_BOTTOM = 2

    TEMPLATES = [
      { id: LARGE_TOP, name: "Up there in the corner" },
      { id: SMALL_BOTTOM, name: "Down in the middle" }
    ]

  end
end
