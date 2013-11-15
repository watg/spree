module Spree
  class IndexPageItem < ActiveRecord::Base
    belongs_to :item, polymorphic: true
    belongs_to :index_page
    
    store_accessor :properties, :css_style

    acts_as_list :scope => :index_page
    default_scope { order('position') }

    def image
      item.images.first
    end

    validates_uniqueness_of :index_page, :scope => :item_id, :message => :already_linked
  end
end
