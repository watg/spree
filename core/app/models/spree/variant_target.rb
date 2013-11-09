module Spree
  class VariantTarget < ActiveRecord::Base
    belongs_to :variant
    belongs_to :target
    has_many :images, -> { order(:position) }, as: :viewable, class_name: "Spree::Image", dependent: :destroy
  
    validates_presence_of :variant_id, :target_id
  end
end
