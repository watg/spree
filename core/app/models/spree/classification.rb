module Spree
  class Classification < ActiveRecord::Base
    belongs_to :product_group_tab, class_name: "Spree::ProductGroupTab"
    belongs_to :taxon, class_name: "Spree::Taxon"

    # For #3494
    validates_uniqueness_of :taxon_id, :scope => :product_group_tab_id, :message => :already_linked
  end
end
