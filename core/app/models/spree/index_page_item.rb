module Spree
  class IndexPageItem < ActiveRecord::Base
    belongs_to :item, polymorphic: true
    belongs_to :index_page
    
    acts_as_list :scope => :index_page

    validates_uniqueness_of :index_page, :scope => :item_id, :message => :already_linked
  end
end
