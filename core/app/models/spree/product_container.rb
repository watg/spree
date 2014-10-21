module Spree
  class ProductContainer < ActiveRecord::Base
    acts_as_paranoid

    validates_uniqueness_of :name, :permalink
    validates_presence_of :name, :permalink, :title

    # has_many :taxons

    belongs_to :target
    has_one :image, as: :viewable, dependent: :destroy, class_name: "Spree::ProductContainerImage"

    has_many :tabs, -> { order(:position) }, dependent: :destroy, class_name: "Spree::ProductContainerTab"

    accepts_nested_attributes_for :tabs, allow_destroy: true

    make_permalink


    def to_param
      permalink.present? ? permalink.to_s.to_url : name.to_s.to_url
    end

  end
end
