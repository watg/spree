module Spree
  class Classification < ActiveRecord::Base
    belongs_to :product_group, class_name: "Spree::ProductGroup"
    belongs_to :taxon, class_name: "Spree::Taxon"
  end
end
