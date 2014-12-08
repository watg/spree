module Spree
  class Classification < ActiveRecord::Base
    acts_as_paranoid

    self.table_name = 'spree_suites_taxons'
    acts_as_list scope: [:taxon_id, :deleted_at]
    belongs_to :suite, class_name: "Spree::Suite", inverse_of: :classifications
    belongs_to :taxon, class_name: "Spree::Taxon", inverse_of: :classifications

    default_scope { order(:position) }
    validates_uniqueness_of :taxon_id, :scope => :suite_id, :message => :already_linked
  end
end
