module Spree
  class IndexPage < ActiveRecord::Base
    belongs_to :item, polymorphic: true
    belongs_to :taxon, class_name: "Spree::Taxon"
    
    acts_as_list :scope => :taxon

    validates_uniqueness_of :taxon_id, :scope => :item_id, :message => :already_linked
  end
end
