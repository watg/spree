module Spree
  class IndexPageItem < ActiveRecord::Base
    belongs_to :item, polymorphic: true
    belongs_to :index_page
    
    acts_as_list :scope => :index_page

  end
end
