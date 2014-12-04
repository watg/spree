module Spree
  class Suite < ActiveRecord::Base
    cattr_accessor :search_scopes do
      []
    end

    def self.add_search_scope(name, &block)
      self.singleton_class.send(:define_method, name.to_sym, &block)
      search_scopes << name.to_sym
    end

    # This scope selects suites in taxon AND all its descendants
    # If you need suite only within one taxon use
    #
    #   Spree::Suite.joins(:taxons).where(Taxon.table_name => { :id => taxon.id })
    #
    # If you're using count on the result of this scope, you must use the
    # `:distinct` option as well:
    #
    #   Spree::Suite.in_taxon(taxon).count(:distinct => true)
    #
    # This is so that the count query is distinct'd:
    #
    #   SELECT COUNT(DISTINCT "spree_suites"."id") ...
    #
    #   vs.
    #
    #   SELECT COUNT(*) ...
    add_search_scope :in_taxon do |taxon|
      includes(:classifications).
      where("spree_suites_taxons.taxon_id" => taxon.self_and_descendants.pluck(:id)).
      order("spree_suites_taxons.position ASC")
    end

    # This scope selects suites in all taxons AND all its descendants
    # If you need suites only within one taxon use
    #
    #   Spree::suite.taxons_id_eq([x,y])
    add_search_scope :in_taxons do |*taxons|
      taxons = get_taxons(taxons)
      taxons.first ? prepare_taxon_conditions(taxons) : scoped
    end

  end
end
