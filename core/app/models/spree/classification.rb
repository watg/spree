module Spree
  class Classification < ActiveRecord::Base
    belongs_to :product_group, class_name: "Spree::ProductGroup"
    belongs_to :taxon, class_name: "Spree::Taxon"

    # For #3494
    validates_uniqueness_of :taxon_id, :scope => :product_id, :message => :already_linked
  end
end
