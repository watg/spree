module Spree
  class IndexPage < ActiveRecord::Base
    has_many :items, class_name: 'Spree::IndexPageItem'
    belongs_to :taxon

    store_accessor :properties, :background_color
    validates_presence_of :name

    TEMPLATES = [
      { id: 1, name: "Up there in the corner" },
      { id: 2, name: "Down in the middle" }
    ]

    accepts_nested_attributes_for :items, allow_destroy: true

  end
end
