module Spree
  class TaxonUpdateService < ActiveInteraction::Base

    model :taxon, class: 'Spree::Taxon'
    hash :params, strip: false

    def execute
      old_parent = taxon.parent

      # TODO: return the correct object for errors
      taxon.update_attributes!(params)

      if old_parent != taxon.parent
        add_suites_to_ancestors(taxon)

        if old_parent
          # It is imporant to reload the old_parent, as we need to 
          # have its' fresh relationships with descendents for the
          # removal of suites further up the stack
          old_parent.reload
          remove_suites_from_ancestors(old_parent, taxon)
        end

      end
    end

    private

    def add_suites_to_ancestors(taxon)
      taxon.suites.each do |suite|
        compose(SuiteUpdate::AddSuiteToAncestorsService, suite: suite, taxon: taxon)
      end
    end

    def remove_suites_from_ancestors(old_parent, taxon)
      taxon.suites.each do |suite|
        compose(SuiteUpdate::RemoveSuiteFromAncestorsService, suite: suite, taxon: old_parent)
      end
    end
  end

end
