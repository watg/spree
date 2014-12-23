module Spree
  class TaxonShowService < Mutations::Command

    required do
      string :permalink
    end

    def execute
      taxon = Taxon.where(permalink: permalink).first
      unless taxon
        parts = permalink.split('/')
        while (parts.any?)
          parts.pop
          if taxon = Taxon.where(permalink: parts.join('/')).first
            return taxon
          end
        end
      end
      taxon
    end

  end
end
