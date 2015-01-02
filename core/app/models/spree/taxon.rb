module Spree
  class Taxon < ActiveRecord::Base
    acts_as_paranoid

    belongs_to :taxonomy, class_name: 'Spree::Taxonomy', touch: true, inverse_of: :taxons

  	has_many :classifications, -> { order(:position) }, dependent: :destroy, inverse_of: :taxon
    has_many :suites, through: :classifications

    # Please do not move this above the has_many classification and suites as it will break
    # the after_destroy callback in classification .... yep dependency and magic !!!
    acts_as_nested_set dependent: :destroy

    before_create :set_permalink

    validates :name, presence: true

    after_touch :touch_parent

    scope :displayable, -> { where(hidden: [false,nil]) }

    has_attached_file :icon,
      styles: { mini: '32x32>', normal: '128x128>' },
      default_style: :mini,
      default_url: '/assets/default_taxon.png'

    validates_attachment :icon,
      content_type: { content_type: ["image/jpg", "image/jpeg", "image/png", "image/gif"] }

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

   
    # We use this instead of self_and_ancesors as this gives us gaurentees about the
    # order of the parents, we would like to walk up the tree
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

    def active_suites
      scope = suites.active
      scope
    end

    def pretty_name
      ancestor_chain = self.ancestors.inject("") do |name, ancestor|
        name += "#{ancestor.name} -> "
      end
      ancestor_chain + "#{name}"
    end

    def title
      name.humanize
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

    # TODO: if we delete a taxon we need to ensure all the classifications down
    # streem get deleted
    
    private

    def touch_parent
      parent.touch if parent
    end
  end
end
