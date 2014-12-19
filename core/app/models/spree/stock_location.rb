module Spree
  class StockLocation < ActiveRecord::Base
    has_many :shipments
    has_many :stock_items, dependent: :delete_all
    has_many :stock_movements, through: :stock_items

    belongs_to :state, class_name: 'Spree::State'
    belongs_to :country, class_name: 'Spree::Country'

    belongs_to :feed_into, class_name: 'Spree::StockLocation'
    has_many :feeders, foreign_key: "feed_into_id", class_name: 'Spree::StockLocation'

    has_many :stock_thresholds,
      class_name: 'Spree::StockThreshold',
      dependent: :destroy

    validates_presence_of :name

    validates_absence_of :feed_into, if: :active?, message: "must be blank for active locations"
    validate :only_feed_into_active_locations

    scope :active, -> { where(active: true) }
    scope :available, -> { where("active = ? OR feed_into_id IS NOT NULL", true) }
    scope :with_feeders, -> { joins(:feeders).uniq }

    after_create :create_stock_items, :if => "self.propagate_all_variants?"

    def self.valid_feed_into_locations_for(location)
      active.where.not(id: location.id)
    end

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

    def unstock(variant, quantity, originator = nil, supplier = nil)
      movement = move(variant, -quantity, originator, supplier)
    end

    def move(variant, quantity, originator = nil, supplier = nil)
      item = stock_item_or_create(variant, supplier)
      item.stock_movements.create!(quantity: quantity, originator: originator)
    end

    def fill_status(variant, quantity)
      if items = available_stock_items(variant)

        count_on_hand_value = items.to_a.sum(&:count_on_hand)#(variant)
        if count_on_hand_value >= quantity
          on_hand = quantity
          backordered = 0
          awaiting_feed = 0
        else
          on_hand = count_on_hand_value
          on_hand = 0 if on_hand < 0
          amount_required = quantity - on_hand

          feeder_count_on_hand_value = feeder_items(variant).sum(&:count_on_hand)
          awaiting_feed = [feeder_count_on_hand_value, amount_required].min
          amount_required = quantity - on_hand - awaiting_feed

          backordered = if items.detect(&:backorderable?) || feeder_items(variant).detect(&:backorderable?)
                          amount_required
                        else
                          0
                        end
        end

        [on_hand, backordered, awaiting_feed]
      else
        [0, 0, 0]
      end
    end

    def available_stock_items(variant)
      stock_items.where(variant_id: variant).available
    end

    def available?
      self.active or !self.feed_into_id.nil?
    end

    def feeder_items(variant)
      # There is an n+1 query issue here - for every variant that isn't on hand
      # in the active location we call available_stock_items for each feeder,
      # which in turn loads stock items. It would be better to load all stock
      # items for all feeders in one query, but given the small number of feeder
      # stores this seems unnecessary at the moment.
      @feeder_items ||= feeders.map { |f| f.available_stock_items(variant) }.flatten
    end

    private

    def create_stock_items
      Variant.find_each { |variant| self.propagate_variant(variant) }
    end

    def only_feed_into_active_locations
      unless feed_into.nil? || feed_into.active?
        errors.add(:feed_into, "can only feed into active locations")
      end
    end
  end
end
