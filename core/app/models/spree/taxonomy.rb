module Spree
  class Taxonomy < Spree::Base
    acts_as_paranoid
    validates :name, presence: true

    has_many :taxons, inverse_of: :taxonomy
    has_one :root, -> { where parent_id: nil }, class_name: "Spree::Taxon", dependent: :destroy

    after_save :set_name
    after_save :clear_navigation_cache_key
    after_touch :clear_navigation_cache_key

    default_scope -> { order("#{self.table_name}.position") }

    NAVIGATION_CACHE_KEY = 'nav_cache_key'

    class << self

      def clear_navigation_cache_key
        Rails.cache.delete(NAVIGATION_CACHE_KEY)
      end

      def navigation_cache_key
        Rails.cache.fetch(NAVIGATION_CACHE_KEY) do
          Time.now.to_i
        end
      end

    end

    def clear_navigation_cache_key
      Spree::Taxonomy.clear_navigation_cache_key
    end

    private
      def set_name
        if root
          root.update_columns(
            name: name,
            updated_at: Time.now,
          )
        else
          self.root = Taxon.create!(taxonomy_id: id, name: name)
        end
      end

  end
end
