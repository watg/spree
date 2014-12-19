module Spree
  class Suite < ActiveRecord::Base
    acts_as_paranoid

    validates_uniqueness_of :name, :permalink
    validates_presence_of :name, :permalink, :title

    # has_many :taxons

    belongs_to :target
    has_one :image, as: :viewable, dependent: :destroy, class_name: "Spree::SuiteImage"

    has_many :classifications, dependent: :destroy, inverse_of: :suite
    has_many :taxons, through: :classifications, dependent: :destroy
    has_many :tabs, -> { order(:position) }, dependent: :destroy, class_name: "Spree::SuiteTab"
    alias_method :suite_tabs, :tabs

    accepts_nested_attributes_for :tabs, allow_destroy: true
    accepts_nested_attributes_for :image, allow_destroy: true

    # TODO this should be a boolean
    scope :active, -> { where(deleted_at: nil) }

    make_permalink

    LARGE_TOP = 1
    SMALL_BOTTOM = 2

    TEMPLATES = [
      { id: LARGE_TOP, name: "top left hand" },
      { id: SMALL_BOTTOM, name: "bottom centre" }
    ]

    def to_param
      permalink.present? ? permalink.to_s.to_url : name.to_s.to_url
    end

  end
end

require_dependency 'spree/suite/scopes'
