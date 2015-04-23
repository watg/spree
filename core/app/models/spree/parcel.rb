module Spree
  class Parcel < ActiveRecord::Base
    attr_accessor :quantity

    belongs_to :order
    has_one :box, class_name: "Spree::Product", foreign_key: :id, primary_key: :box_id

    validates :box_id, presence: true
    validates :order_id, presence: true
    validates :weight, presence: true
    validates :width, presence: true
    validates :height, presence: true
    validates :depth, presence: true


    def longest_edge
      [box.height, box.width, box.depth].sort { |a,b| b <=> a }.first
    end

    class << self
      def find_boxes
        Spree::Product
          .joins(:product_type)
          .merge(Spree::ProductType.where(name: Spree::ProductType::TYPES[:packaging]))
      end
    end
  end
end
