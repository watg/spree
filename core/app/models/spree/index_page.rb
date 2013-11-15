module Spree
  class IndexPage < ActiveRecord::Base
    has_many :items, class_name: 'Spree::IndexPageItem'
    belongs_to :taxon

  end
end
