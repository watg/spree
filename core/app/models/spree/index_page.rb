module Spree
  class IndexPage < ActiveRecord::Base
    has_many :items, class_name: 'Spree::IndexPageItem'
    has_many :index_page_items
    has_many :taxons, as: :page

    belongs_to :taxon # remove after migration and drop the column
    validates_presence_of :name

    accepts_nested_attributes_for :items, allow_destroy: true
  end
end
