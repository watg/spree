module Spree
  class SuiteScope < ActiveRecord::Base
    before_validation(:on => :create) do
      # Add default empty arguments so scope validates and errors aren't caused when previewing it
      if name && args = self.class.arguments_for_scope_name(name)
        self.arguments ||= ['']*args.length
      end
    end

    def self.all_scopes
      {
        # Scopes for selecting suites based on taxon
        :taxon => {
          :taxons_name_eq => [:taxon_name],
          :in_taxons => [:taxon_names],
        },
      }
    end

    def self.arguments_for_scope_name(name)
      if group = all_scopes.detect { |k,v| v[name.to_sym] }
        group[1][name.to_sym]
      end
    end
  end
end
