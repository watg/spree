module Spree
  class Parcel < ActiveRecord::Base
    attr_accessor :quantity
    attr_accessible :box_id, :order_id, :metapack_tracking_code, :metapack_tracking_url
    
    belongs_to :order
    has_one :box, class_name: "Spree::Product", foreign_key: :id, primary_key: :box_id
    
    validates :box_id, presence: true
    validates :order_id, presence: true

    def longest_edge
      [box.height, box.width, box.depth].sort { |a,b| b <=> a }.first 
    end
    
    class << self
      def find_boxes
        Spree::Product.joins(:product_group).where('spree_product_groups.name' => 'box').all
      end
    end
  end
end
