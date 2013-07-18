module Spree
  class StockLocation < ActiveRecord::Base
    has_many :stock_items, dependent: :destroy
    has_many :stock_movements, through: :stock_items

    belongs_to :state, class_name: 'Spree::State'
    belongs_to :country, class_name: 'Spree::Country'

    validates_presence_of :name

    attr_accessible :name, :active, :address1, :address2, :city, :zipcode,
        :backorderable_default, :state_name, :state_id, :country_id, :phone,
        :country_id

    scope :active, -> { where(active: true) }

    after_create :create_stock_items

    def stock_item(variant)
      stock_items.where(variant_id: variant).order(:id).first
    end

    def stock_item_or_create(variant)
      stock_item(variant) || stock_items.create(variant: variant)
    end

    def count_on_hand(variant)
      stock_item(variant).try(:count_on_hand)
    end

    def backorderable?(variant)
      stock_item(variant).try(:backorderable?)
    end

    def restock(variant, quantity, originator = nil)
      move(variant, quantity, originator)
    end

    def unstock(variant, quantity, originator = nil)
      move(variant, -quantity, originator)
    end

    def move(variant, quantity, originator = nil)
      stock_item_or_create(variant).stock_movements.create!(quantity: quantity,
                                                            originator: originator)
    end

    def fill_status(variant, quantity)
      if item = stock_item(variant)

        if item.count_on_hand >= quantity
          on_hand = quantity
          backordered = 0
        else
          on_hand = item.count_on_hand
          on_hand = 0 if on_hand < 0
          backordered = item.backorderable? ? (quantity - on_hand) : 0
        end

        [on_hand, backordered]
      else
        [0, 0]
      end
    end

    private
      def create_stock_items
        Spree::Variant.find_each do |v|
          self.stock_items.create!(variant: v, backorderable: self.backorderable_default)
        end
      end
  end
end
