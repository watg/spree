module Spree
  class IndexPage < ActiveRecord::Base
    has_many :items, class_name: 'Spree::IndexPageItem'
    belongs_to :taxon

    validates_presence_of :name, :taxon
  end
end
