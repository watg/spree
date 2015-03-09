module Spree
  class SuiteUpdateService < ActiveInteraction::Base

    model :suite, class: 'Spree::Suite'
    hash :params, strip: false

    def execute
      taxon_ids = (params.delete(:taxon_ids) || []).map(&:to_i)
      existing_taxon_ids = suite.taxons.map(&:id).map(&:to_i)
      # This will not update taxons as we have deleted them from
      # the params, this will be updated below manually
      suite.update_attributes!(confirm_tab_attributes(params))

      update_suites(suite, taxon_ids, existing_taxon_ids)
      rebuild_suite_tabs_cache(suite)
    end

    private

    # confirm that each tab has a cross_sale_ids attribute
    def confirm_tab_attributes(parameters)
      parameters[:tabs_attributes] = parameters[:tabs_attributes].each do |tab|
        tab.last[:cross_sale_ids] ||= []
        tab
      end
      parameters
    end

    def update_suites(suite, taxon_ids, existing_taxon_ids)
      taxon_ids_to_add = taxon_ids - existing_taxon_ids
      taxon_ids_to_remove = existing_taxon_ids - taxon_ids

      classifications = add_taxons(taxon_ids_to_add, suite)
      promote_classifications(classifications)

      remove_taxons(taxon_ids_to_remove, suite)
    end

    def add_taxons(taxon_ids_to_add, suite)
      classifications = []
      taxon_ids_to_add.each do |taxon_id|
        taxon = Spree::Taxon.find taxon_id
        classifications << Spree::Classification.find_or_create_by(suite_id: suite.id, taxon_id: taxon_id)
        classifications += compose(SuiteUpdate::AddSuiteToAncestorsService, suite: suite, taxon: taxon)
      end
      classifications
    end

    def remove_taxons(taxon_ids_to_remove, suite)
      taxon_ids_to_remove.each do |taxon_id|
        taxon = Spree::Taxon.find taxon_id

        Spree::Classification.where(suite_id: suite.id, taxon_id: taxon_id).destroy_all

        compose(SuiteUpdate::RemoveSuiteFromAncestorsService, suite: suite, taxon: taxon)
        compose(SuiteUpdate::RemoveSuiteFromDescendantsService, suite: suite, taxon: taxon)
      end
    end

    def rebuild_suite_tabs_cache(suite)
      suite.tabs.each do |tab|
        Spree::SuiteTabCacheRebuilder.rebuild_from_product(tab.product)
      end
    end

    def promote_classifications(classifications)
      classifications.each do |classification|
        classification.send_to_top
      end
    end
  end
end
