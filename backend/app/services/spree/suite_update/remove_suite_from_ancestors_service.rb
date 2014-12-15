module Spree
  module SuiteUpdate

    class RemoveSuiteFromAncestorsService < ActiveInteraction::Base

      model :suite, class: 'Spree::Suite'
      model :taxon, class: 'Spree::Taxon'

      def execute
        self_and_descendant_ids = taxon.self_and_descendants.map(&:id)

        # Need to use self and parents as this gaurentees the order
        # it is important we walk up the tree
        taxon.self_and_parents.each do |taxon|

          # Ensure we only destroy ancestors classifications that do not have a 
          # dependency on another descendant ignoring our self
          descendant_ids = taxon.descendants.map(&:id) - self_and_descendant_ids
          next if Spree::Classification.where( suite_id: suite.id, taxon_id: descendant_ids ).any?

          classification = Spree::Classification.where(suite_id: suite.id, taxon_id: taxon.id).first
          classification.destroy if classification

        end
      end

    end
  end
end


