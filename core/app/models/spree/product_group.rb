module Spree
  class ProductGroup < ActiveRecord::Base
    attr_accessible :name, :description, :taxon_ids
    validates :name, :presence => true

    has_many :products
    has_many :classifications, dependent: :delete_all
    has_many :taxons, through: :classifications

    # This will help us clear the caches if a product is modified
    after_touch { self.delay.touch_taxons }

    def touch_taxons
      # You should be able to just call self.taxons.each { |t| t.touch } but
      # for some reason acts_as_nested_set does not walk all the ancestors
      # correclty
      self.taxons.each { |t| t.self_and_parents.each { |t2| t2.touch } }
    end
  end
end
