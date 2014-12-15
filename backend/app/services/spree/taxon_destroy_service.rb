module Spree
  class TaxonDestroyService < ActiveInteraction::Base

    model :taxon, class: 'Spree::Taxon'

    def execute
      taxon.children.map(&:destroy)
      remove_suites_from_ancestors(taxon)
      taxon.destroy
    end

    private

    def remove_suites_from_ancestors(taxon)
      taxon.suites.each do |suite|
        compose(SuiteUpdate::RemoveSuiteFromAncestorsService, suite: suite, taxon: taxon)
      end
    end

  end
end
