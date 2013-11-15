module Spree
  class IndexPage < ActiveRecord::Base
    has_many :items, class_name: 'Spree::IndexPageItem'
    belongs_to :taxon

    store_accessor :properties, :background_color

    validates_presence_of :name, :taxon
  end
end
