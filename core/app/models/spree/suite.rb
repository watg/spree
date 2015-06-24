module Spree
  class Suite < ActiveRecord::Base
    acts_as_paranoid

    has_one :indexed_search, foreign_key: :suite_id, class_name: "IndexedSearch"

    validates_uniqueness_of :name, :permalink
    validates_presence_of :name, :permalink, :title
    belongs_to :category, class: SuiteCategory, foreign_key: :category_id
    belongs_to :target
    has_one :image, as: :viewable, dependent: :destroy, class_name: "Spree::SuiteImage"

    has_many :classifications, dependent: :destroy, inverse_of: :suite
    has_many :taxons, through: :classifications, dependent: :destroy
    has_many :tabs, -> { order(:position) }, dependent: :destroy, class_name: "Spree::SuiteTab"
    alias_method :suite_tabs, :tabs
    has_many :line_items, class_name: "Spree::LineItem"

    accepts_nested_attributes_for :tabs, allow_destroy: true
    accepts_nested_attributes_for :image, allow_destroy: true

    # TODO this should be a boolean
    scope :active, -> { where(deleted_at: nil) }
    scope :indexable, -> { where(indexable: true) }

    make_permalink

    LARGE_TOP = 1
    SMALL_BOTTOM = 2

    TEMPLATES = [
      { id: LARGE_TOP, name: "top left hand" },
      { id: SMALL_BOTTOM, name: "bottom centre" }
    ]

    class << self
      def active
        joins(:tabs) # to ensure that tabs are present
      end
    end


    def to_param
      permalink.present? ? permalink.to_s.to_url : name.to_s.to_url
    end

  end
end
