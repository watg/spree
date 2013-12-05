module Spree
  class IndexPage < ActiveRecord::Base
    has_many :items, class_name: 'Spree::IndexPageItem'
    belongs_to :taxon, touch: true

    validates_presence_of :name

    accepts_nested_attributes_for :items, allow_destroy: true
  end
end
