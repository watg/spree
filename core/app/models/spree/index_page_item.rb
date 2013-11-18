module Spree
  class IndexPageItem < ActiveRecord::Base
    belongs_to :item, polymorphic: true
    belongs_to :index_page

    default_scope { order('position') }
    acts_as_list :scope => :index_page
    
    validates_uniqueness_of :index_page, :scope => :item_id, :message => :already_linked

    def image
      item.variant_images.first
    end

    def name
      item.name
    end

  end
end
