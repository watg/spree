module Spree
  class SuiteUpdateService < ActiveInteraction::Base

    model :suite, class: 'Spree::Suite'
    hash :params, strip: false

    def execute
      taxon_ids = (params[:taxon_ids] || []).map(&:to_i)
      existing_taxon_ids = suite.taxons.map(&:id).map(&:to_i)

      suite.update_attributes!(params)

      update_suites(suite, taxon_ids, existing_taxon_ids)
      rebuild_suite_tabs_cache(suite)
    end

    private

    def update_suites(suite, taxon_ids, existing_taxon_ids)
      taxon_ids_to_add = taxon_ids - existing_taxon_ids
      taxon_ids_to_remove = existing_taxon_ids - taxon_ids

      taxon_ids_to_add.each do |taxon_id|
        taxon = Spree::Taxon.find taxon_id
        compose(SuiteUpdate::AddSuiteToAncestorsService, suite: suite, taxon: taxon)
      end

      taxon_ids_to_remove.each do |taxon_id|
        taxon = Spree::Taxon.find taxon_id
        compose(SuiteUpdate::RemoveSuiteFromAncestorsService, suite: suite, taxon: taxon)
        compose(SuiteUpdate::RemoveSuiteFromDescendantsService, suite: suite, taxon: taxon)
      end
    end

    def rebuild_suite_tabs_cache(suite)
      suite.tabs.each do |tab|
        Spree::SuiteTabCacheRebuilder.rebuild_from_product(tab.product)
      end
    end

  end
end
