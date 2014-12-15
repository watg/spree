module Spree
  module SuiteUpdate

    class RemoveSuiteFromDescendantsService < ActiveInteraction::Base

      model :suite, class: 'Spree::Suite'
      model :taxon, class: 'Spree::Taxon'

      def execute
        taxon.descendants.map(&:classifications).flatten.map do |c|
          c.delete if c.suite_id == suite.id
        end
      end

    end
  end
end


