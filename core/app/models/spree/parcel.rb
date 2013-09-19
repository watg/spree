module Spree
  class Parcel < ActiveRecord::Base
    attr_accessor :quantity
    attr_accessible :box_id, :order_id
    
    belongs_to :order
    has_one :box, class_name: "Spree::Product", foreign_key: :id, primary_key: :box_id
    
    validates :box_id, presence: true
    validates :order_id, presence: true

    class << self
      def find_boxes
        Spree::Product.joins(:product_group).where('spree_product_groups.name' => 'box').all
      end
    end
  end
end
