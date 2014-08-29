module Spree
  class StockLocation < ActiveRecord::Base
    has_many :shipments
    has_many :stock_items, dependent: :delete_all
    has_many :stock_movements, through: :stock_items

    belongs_to :state, class_name: 'Spree::State'
    belongs_to :country, class_name: 'Spree::Country'

    validates_presence_of :name

    scope :active, -> { where(active: true) }

    after_create :create_stock_items, :if => "self.propagate_all_variants?"

    # Wrapper for creating a new stock item respecting the backorderable config
    def propagate_variant(variant, supplier=nil)
      create_params = { variant: variant, backorderable: self.backorderable_default }
      create_params.merge!( supplier: supplier ) if supplier
      self.stock_items.create!(create_params)
    end

    # Return either an existing stock item or create a new one. Useful in
    # scenarios where the user might not know whether there is already a stock
    # item for a given variant
    def set_up_stock_item(variant, supplier=nil)
      self.stock_item(variant, supplier) || propagate_variant(variant, supplier)
    end

    def stock_item_or_create(variant, supplier=nil)
      stock_item(variant, supplier) || create_stock_item(variant, supplier)
    end

    def create_stock_item(variant, supplier=nil)
      si = stock_items.create(variant: variant)
      si.supplier = supplier if supplier
      si.save
      si
    end

    def stock_item(variant, supplier=nil)
      items = stock_items.where(variant_id: variant)
      items = items.where(supplier_id: supplier) if supplier
      items.order(:id).first
    end

    def count_on_hand(variant, supplier=nil)
      items = stock_items.where(variant_id: variant)
      items = items.where(supplier_id: supplier) if supplier
      items.to_a.sum(&:count_on_hand)
    end

    # Please note this is not used, although if it does get used
    # we need to add the supplier code
    def backorderable?(variant, supplier=nil)
      items = stock_items.where(variant_id: variant)
      items = items.where(supplier_id: supplier) if supplier
      items.first.try(:backorderable?)
    end

    def restock(variant, quantity, originator = nil, supplier = nil)
      move(variant, quantity, originator, supplier)
    end

    def restock_backordered(variant, quantity, supplier = nil)
      item = stock_item_or_create(variant)
      item.update_columns(
        count_on_hand: item.count_on_hand + quantity,
        updated_at: Time.now
      )
    end

    def unstock(variant, quantity, originator = nil, supplier = nil)
      movement = move(variant, -quantity, originator, supplier)
      movement.stock_item.update_columns(last_unstocked_at: Time.now)
    end

    def move(variant, quantity, originator = nil, supplier = nil)
      item = stock_item_or_create(variant, supplier)
      item.stock_movements.create!(quantity: quantity, originator: originator)
    end

    def stock_items_on_hand(variant)
      stock_items.where(variant_id: variant).order(:last_unstocked_at)
    end

    def stock_items_backorderable(variant)
      stock_items.where(variant_id: variant, backorderable: true ).order(:id)
    end

    FillStatusItem = Struct.new(:supplier, :count)

    # Round = RObin fall back

    # This takes an optional list of suppliers which will try and
    # satisfy the fill status with supplier stock in that order
    # If the list is not supplied it will choose first list all the suppliers
    # that can fully satisfy the order, then take the one that had the last sale
    # variant: Spree::Variant
    # quantity: integer
    # Params:
    # +variant+: object - Spree::Variant object
    # +quantity+: integer - number of variants required 
    # +supplier+: array - a preference list of suppliers and the desired quantity
    def fill_status(variant, quantity, suppliers=[])

      on_hand = []
      items = stock_items_on_hand(variant)

      # See if we can satisfy the requst with 1 supplier
      if item = items.detect { |item| item.count_on_hand >= quantity }
        on_hand = [ FillStatusItem.new( item.supplier, quantity ) ]
      else
        on_hand = fill_with_on_hand(items, quantity)
      end

      backordered = []

      if item = stock_items_backorderable(variant).first
        needed = quantity - on_hand.sum(&:count)
        if needed > 0
          backordered << FillStatusItem.new( item.supplier, needed  )
        end
      end

      [on_hand, backordered]
    end

    private


    def fill_with_on_hand(items, quantity)
      # Only exit the loop once we have either satisified the qauntity
      # we need or we have checked all our stock items for this variant
      on_hand = []
      while ( count = on_hand.sum(&:count) ) < quantity and items.any?
        item = items.pop
        needed = quantity - count
        if item.count_on_hand > 0
          if item.count_on_hand >= needed
            on_hand << FillStatusItem.new( item.supplier, needed )
          else
            on_hand << FillStatusItem.new( item.supplier, item.count_on_hand )
          end
        end
      end
      on_hand
    end

    def fill_with_backordered(item)
    end

    def create_stock_items
      Variant.find_each { |variant| self.propagate_variant(variant) }
    end

  end
end
