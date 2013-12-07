module Spree
  class Taxon < ActiveRecord::Base
    acts_as_paranoid
    acts_as_nested_set dependent: :destroy

    belongs_to :taxonomy, class_name: 'Spree::Taxonomy', :touch => true
    belongs_to :page, polymorphic: true

    has_many :classifications, :dependent => :destroy
    has_many :products, through: :classifications
    has_many :displayable_variants, :dependent => :destroy

    before_create :set_permalink

    validates :name, presence: true

    has_attached_file :icon,
      styles: { mini: '32x32>', normal: '128x128>' },
      default_style: :mini,
      url: '/spree/taxons/:id/:style/:basename.:extension',
      path: ':rails_root/public/spree/taxons/:id/:style/:basename.:extension',
      default_url: '/assets/default_taxon.png'

#    default_scope -> { order("#{self.table_name}.position") }

    include Spree::Core::S3Support
    supports_s3 :icon

    include Spree::Core::ProductFilters  # for detailed defs of filters

    # indicate which filters should be used for a taxon
    # this method should be customized to your own site
    def applicable_filters
      fs = []
      # fs << ProductFilters.taxons_below(self)
      ## unless it's a root taxon? left open for demo purposes

      fs << Spree::Core::ProductFilters.price_filter if Spree::Core::ProductFilters.respond_to?(:price_filter)
      fs << Spree::Core::ProductFilters.brand_filter if Spree::Core::ProductFilters.respond_to?(:brand_filter)
      fs
    end

    def displayable_variants(currency=nil)
      Spree::Variant.active(currency).not_deleted.available.includes(:displayable_variants).
        where([" spree_displayable_variants.taxon_id = ? and spree_displayable_variants.deleted_at is null", self.id ]).
        order("spree_variants.id desc")
    end

    # This is method is here as awesome_nested_set method self_and_ancestors in version 2.1.6 does not seem to work
    def self_and_parents
      parents = [self]
      child = self.dup
      while child.parent do
        parents << child.parent
        child = child.parent
      end
      parents
    end

    # Return meta_title if set otherwise generates from root name and/or taxon name
    def seo_title
      if meta_title
        meta_title
      else
        root? ? name : "#{root.name} - #{name}"
      end
    end

    # Creates permalink based on Stringex's .to_url method
    def set_permalink
      if parent.present?
        self.permalink = [parent.permalink, (permalink.blank? ? name.to_url : permalink.split('/').last)].join('/')
      else
        self.permalink = name.to_url if permalink.blank?
      end
    end

    # For #2759
    def to_param
      permalink
    end

    def active_products
      scope = products.active
      scope
    end

    def pretty_name
      self.self_and_parents.map(&:name).reverse.join(' -> ')
    end
    def pretty_name_old
      ancestor_chain = self.ancestors.inject("") do |name, ancestor|
        name += "#{ancestor.name} -> "
      end
      ancestor_chain + "#{name}"
    end

    # awesome_nested_set sorts by :lft and :rgt. This call re-inserts the child
    # node so that its resulting position matches the observable 0-indexed position.
    # ** Note ** no :position column needed - a_n_s doesn't handle the reordering if
    #  you bring your own :order_column.
    #
    #  See #3390 for background.
    def child_index=(idx)
      move_to_child_with_index(parent, idx.to_i) unless self.new_record?
    end

  end
end
