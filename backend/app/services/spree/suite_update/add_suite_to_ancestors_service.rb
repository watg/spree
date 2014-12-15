module Spree
  module SuiteUpdate

    class AddSuiteToAncestorsService < ActiveInteraction::Base

      model :suite, class: 'Spree::Suite'
      model :taxon, class: 'Spree::Taxon'

      def execute
        taxon.ancestors.each do |ancestor|
          Spree::Classification.find_or_create_by(suite_id: suite.id, taxon_id: ancestor.id)
        end
      end

    end
  end
end


