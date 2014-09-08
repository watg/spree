module Spree
  class Variant < ActiveRecord::Base
    acts_as_paranoid

    belongs_to :product, touch: true, class_name: 'Spree::Product', inverse_of: :variants
    belongs_to :tax_category, class_name: 'Spree::TaxCategory'

    delegate_belongs_to :product, :name, :description, :slug, :available_on,
                        :shipping_category_id, :meta_description, :meta_keywords,
                        :shipping_category

    has_many :inventory_units
    has_many :line_items, inverse_of: :variant

    has_many :stock_items, dependent: :destroy, inverse_of: :variant
    has_many :stock_locations, through: :stock_items
    has_many :suppliers, through: :stock_items
    has_many :stock_movements
    has_many :displayable_variants

    has_and_belongs_to_many :option_values, join_table: :spree_option_values_variants, class_name: "Spree::OptionValue"

    has_many :images, -> { order(:position) }, as: :viewable, dependent: :destroy, class_name: "Spree::Image"

    has_many :variant_targets, class_name: 'Spree::VariantTarget', dependent: :destroy
    has_many :targets, class_name: 'Spree::Target', through: :variant_targets

    has_many :assembly_definition_variants, class_name: 'Spree::AssemblyDefinitionVariant'

    has_one :default_price,
      -> { where currency: Spree::Config[:currency] },
      class_name: 'Spree::Price',
      dependent: :destroy

    delegate_belongs_to :default_price, :display_price, :display_amount, :price, :price=, :currency

    delegate_belongs_to :product, :assembly_definitions

    has_many :prices,
      class_name: 'Spree::Price',
      dependent: :destroy,
      inverse_of: :variant

    validate :check_price
    validates :price, numericality: { greater_than_or_equal_to: 0 }

    validates :cost_price, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
    validates :weight, numericality: { greater_than_or_equal_to: 0, allow_nil: true }

    has_many :taggings, as: :taggable
    has_many :tags, -> { order(:value) }, through: :taggings

    has_many :index_page_items

    has_one :assembly_definition

    before_validation :set_cost_currency
    before_validation :generate_variant_number, on: :create

    after_save :save_default_price
    before_create :create_sku
    after_create :create_stock_items
    after_create :set_position
    after_touch :touch_index_page_items

    # This can take a while so run it asnyc with a low priority for now
    after_touch { delay(:priority => 20).touch_assemblies_parts if self.assemblies.any? }

    has_many :assembly_products ,-> { uniq }, through: :assembly_definition_variants
    after_save { delay(:priority => 20 ).touch_assembly_products if assembly_products.any? }

    after_touch :clear_in_stock_cache

    # default variant scope only lists non-deleted variants
    scope :deleted, lambda { where.not(deleted_at: nil) }

    scope :not_deleted, lambda { where("#{Variant.quoted_table_name}.deleted_at IS NULL or #{Variant.quoted_table_name}.deleted_at >= ?", Time.zone.now) }

    scope :available, lambda { joins(:product).where("spree_products.available_on <= ?", Time.zone.now)  }

    scope :in_stock, lambda { where(in_stock_cache: true) }

    NUMBER_PREFIX = 'V'

    # This will be used to setup the first stock item for the variant
    attr_accessor :supplier

    def previous
      self.product.variants.where("position < ?", self.position).last
    end

    def next
      self.product.variants.where("position > ?", self.position).first
    end

    class << self

      def physical
        joins(product: [:product_type]).where('spree_product_types.is_digital = ?', false)
      end

      def active(currency = nil)
        includes(:normal_prices).where(deleted_at: nil).where('spree_prices.currency' => currency || Spree::Config[:currency]).where('spree_prices.amount IS NOT NULL')
      end

      def displayable(product_id)
        where(product_id: product_id, is_master: false).includes(:displayable_variants)
      end

      def options_by_product(product, option_value_name_list)
        _option_values = Spree::OptionValue.select(:id).where(name: option_value_name_list).map(&:id).compact.sort
        product.variants.detect {|v| v.option_values.map(&:id).sort == _option_values}
      end

      def lowest_priced_variant(currency, in_sale: false )
        selector = in_stock.active(currency).select('spree_prices.id').includes(:normal_prices)
          .where('sale = ?', in_sale )

        selector = selector.where('spree_variants.in_sale = ?', in_sale) if in_sale == true

        selector.reorder('amount').first
      end

      def options_tree_for(target, currency, option_type=nil)
        selector = self.includes(:prices, :images, :option_values => [:option_type])
        if !target.blank?
          selector = selector.joins(:variant_targets).where("spree_variant_targets.target_id = ?", target.id)
        end
        variants = selector.order( "spree_option_types.position", "spree_option_values.position", "spree_assets.position" )

        hash={}
        variants.each do |v|
          base=hash

          # Allow us to pass in an option type so we only pass back a tree with
          # a depth of 1
          option_values = v.option_values
          if !option_type.blank?
            option_values = option_values.where(option_type: option_type)
          end

          option_values.each_with_index do |o,i|
            base[o.option_type.url_safe_name] ||= {}
            base[o.option_type.url_safe_name][o.url_safe_name] ||= {}
            base = base[o.option_type.url_safe_name][o.url_safe_name]
          end
          base['variant'] ||= {}
          base['variant']['id']=v.id
          base['variant']['normal_price']=v.price_normal_in(currency).in_subunit
          base['variant']['sale_price']=v.price_normal_sale_in(currency).in_subunit
          base['variant']['part_price']=v.price_part_in(currency).in_subunit
          base['variant']['in_sale']=v.in_sale
          base['variant']['in_stock']= v.in_stock_cache
          base['variant']['total_on_hand']= v.total_on_hand
          if v.images.any?
            #base['variant']['image_url']= v.images.reorder(:position).first.attachment.url(:mini)
            # above replaced by below, as it was causing extra sql queries
            base['variant']['image_url']= v.images.first.attachment.url(:mini)
          end
        end
        hash
      end

    end

    def memoized_images
      @_memoized_images ||= images
    end

    def is_master_but_has_variants?
      self.is_master? and self.product.variants and self.product.variants.any?
    end

    def generate_variant_number(force: false)
      record = true
      while record
        random = "#{NUMBER_PREFIX}#{Array.new(9){rand(9)}.join}"
        record = self.class.where(number: random).first
      end
      self.number = random if self.number.blank? || force
      self.number
    end


    def self.is_number(variant_id)
      return false if variant_id.blank?
      !variant_id.match(/^#{NUMBER_PREFIX}\d+/).nil?
    end

    def images_for(target)
      images.with_target(target)
    end

    def visible?
      displayable_variants.any?
    end

    def weight
      return super if self.is_master || self.new_record?
      return self.product.master.weight if super.blank?
      super
    end

    def cost_price
      return super if self.is_master || self.new_record?
      return self.product.master.cost_price if super.blank?
      super
    end

    def tax_category
      if self[:tax_category_id].nil?
        product.tax_category
      else
        TaxCategory.find(self[:tax_category_id])
      end
    end

    def cost_price=(price)
      self[:cost_price] = parse_price(price)
    end

    # returns number of units currently on backorder for this variant.
    def on_backorder
      inventory_units.with_state('backordered').size
    end

    # from variant options
    def to_hash(currency)
      {
        :id    => self.id,
        :price => current_price_in(currency).display_price.to_s
      }
    end
    # end variant options

    # TODO move this into a decorator as it is view centric
    def price_types
      types = [:normal,:normal_sale]
      unless product.assembly?
        types << [:part, :part_sale]
      end
      types.flatten
    end

    def visible_price_types
      Spree::Price::TYPES - [:part_sale]
    end

    def currency
      Spree::Config[:currency]
    end

    def display_amount
      current_price_in( Spree::Config[:currency] ).display_amount
    end

    def display_price
      current_price_in( Spree::Config[:currency] ).display_price
    end

    #############################################

    def current_price_in(currency_code)
      self.in_sale? ? price_normal_sale_in(currency_code) : price_normal_in(currency_code)
    end

    def price_for_type(type,currency_code)
      t = type.to_s.downcase
      price_in_method = "price_#{t}_in".to_sym
      self.send(price_in_method, currency_code )
    end

    # --- new price getters --------
    def price_normal_in(currency_code)
      find_normal_price(currency_code, :regular) || Spree::Price.new(variant_id: self.id, currency: currency_code, is_kit: false, sale: false)
    end

    def price_normal_sale_in(currency_code)
      find_normal_price(currency_code, :sale) || Spree::Price.new(variant_id: self.id, currency: currency_code, is_kit: false, sale: true)
    end

    def price_part_in(currency_code)
      find_part_price(currency_code, :regular) || Spree::Price.new(variant_id: self.id, currency: currency_code, is_kit: true, sale: false)
    end

    def price_part_sale_in(currency_code)
      find_part_price(currency_code, :sale) || Spree::Price.new(variant_id: self.id, currency: currency_code, is_kit: true, sale: true)
    end
    # ------------------------------

    def price_in(currency)
      ActiveSupport::Deprecation.warn("variant#price_in is deprecated use price_normal_in instead")
      price_normal_in(currency)
    end

    def kit_price_in(currency)
      ActiveSupport::Deprecation.warn("variant#kit_price_in is deprecated use price_part_in instead")
      price_part_in(currency)
    end

    def display_name

      # retrieve all the option type ids which are visible, we have to go up to the product to retrieve this information
      option_type_ids = self.product.product_option_types.where( visible: true ).joins(:option_type).map(&:option_type_id)

      # Now retrieve the option values
      values = self.option_values.where( option_type_id: option_type_ids )

      values.map! do |ov|
        ov.presentation
      end

      values.to_sentence({ words_connector: ", ", two_words_connector: ", " })
    end

    def options_text
      values = self.option_values.sort do |a, b|
        a.option_type.position <=> b.option_type.position
      end

      values.map! do |ov|
        "#{ov.option_type.presentation}: #{ov.presentation}"
      end

      values.to_sentence({ words_connector: ", ", two_words_connector: ", " })
    end

    #def gross_profit
    #  cost_price.nil? ? 0 : (price - cost_price)
    #end

    # use deleted? rather than checking the attribute directly. this
    # allows extensions to override deleted? if they want to provide
    # their own definition.
    def deleted?
      !!deleted_at
    end

    # Product may be created with deleted_at already set,
    # which would make AR's default finder return nil.
    # This is a stopgap for that little problem.
    def product
      Spree::Product.unscoped { super }
    end

    def default_price
      Spree::Price.unscoped { super }
    end

    def options=(options = {})
      options.each do |option|
        set_option_value(option[:name], option[:value])
      end
    end

    def set_option_value(opt_name, opt_value)
      # no option values on master
      return if self.is_master

      option_type = Spree::OptionType.where(name: opt_name).first_or_initialize do |o|
        o.presentation = opt_name
        o.save!
      end

      current_value = self.option_values.detect { |o| o.option_type.name == opt_name }

      unless current_value.nil?
        return if current_value.name == opt_value
        self.option_values.delete(current_value)
      else
        # then we have to check to make sure that the product has the option type
        unless self.product.option_types.include? option_type
          self.product.option_types << option_type
        end
      end

      option_value = Spree::OptionValue.where(option_type_id: option_type.id, name: opt_value).first_or_initialize do |o|
        o.presentation = opt_value
        o.save!
      end

      self.option_values << option_value
      self.save
    end

    def option_value(opt_name)
      self.option_values.detect { |o| o.option_type.name == opt_name }.try(:presentation)
    end

    def amount_in(currency)
      price_normal_in(currency).try(:amount)
    end

    def name_and_sku
      "#{name} - #{sku}"
    end

    # The new in_stock? is using Rails cache
    # def in_stock?(quantity=1)
    #  Spree::Stock::Quantifier.new(self).can_supply?(quantity)
    # end

    def sku_and_options_text
      "#{sku} #{options_text}".strip
    end

    def in_stock?
      Rails.cache.fetch(in_stock_cache_key) do
        total_on_hand > 0
      end
    end

    def can_supply?(quantity=1)
      Spree::Stock::Quantifier.new(self).can_supply?(quantity)
    end

    def total_on_hand
      Spree::Stock::Quantifier.new(self).total_on_hand
    end

    def product_price_in(currency)
      self.product.master.normal_prices.select{ |price| price.currency == currency }.first
    end

    def tag_names
      self.tags.map(&:value)
    end

    def option_types_and_values
      option_values.includes(:option_type).references(:option_type).reorder( "spree_option_types.position", "spree_option_values.position" )
        .map{ |ov| [ ov.option_type.url_safe_name, ov.url_safe_name, ov.presentation] }
    end

    # Shortcut method to determine if inventory tracking is enabled for this variant
    # This considers both variant tracking flag and site-wide inventory tracking settings
    def should_track_inventory?
      self.track_inventory? && Spree::Config.track_inventory_levels
    end

    def assembly_definition_parts
      assembly_definition.try(:parts) || []
    end

    private

    def touch_assembly_products
      assembly_products.map(&:touch)
    end

    def find_normal_price(currency, type)
      prices.select{ |price| price.currency == currency && price.sale == (type == :sale) && (price.is_kit == false) }.first
    end

    def find_part_price(currency, type)
      prices.select{ |price| price.currency == currency && price.sale == (type == :sale) && (price.is_kit == true) }.first
    end

    def touch_assemblies_parts
      Spree::AssembliesPart.where(part_id: self.id).map(&:touch)
    end

    # strips all non-price-like characters from the price, taking into account locale settings
    def parse_price(price)
      return price unless price.is_a?(String)

      separator, _delimiter = I18n.t([:'number.currency.format.separator', :'number.currency.format.delimiter'])
      non_price_characters = /[^0-9\-#{separator}]/
      price.gsub!(non_price_characters, '') # strip everything else first
      price.gsub!(separator, '.') unless separator == '.' # then replace the locale-specific decimal separator with the standard separator if necessary

      price.to_d
    end

    # Ensures a new variant takes the product master price when price is not supplied
    def check_price
      if price == 0
        self.price = product.master.try(:price)
      elsif price.nil? && Spree::Config[:require_master_price]
        raise 'No master variant found to infer price' unless (product && product.master)
        raise 'Must supply price for variant or master.price for product.' if self == product.master
        self.price = product.master.price
      end
      if currency.nil?
        self.currency = Spree::Config[:currency]
      end
    end

    def save_default_price
      default_price.save if default_price && (default_price.changed? || default_price.new_record?)
    end

    def set_cost_currency
      self.cost_currency = Spree::Config[:currency] if cost_currency.nil? || cost_currency.empty?
    end

    def create_stock_items
      StockLocation.all.each do |stock_location|
        if stock_location.propagate_all_variants?
          stock_location.propagate_variant(self, supplier)
        end
      end
    end

    def create_sku
      unless self.sku.present?
        sku_parts = [ product.master.sku ] + self.option_values.map { |ov| [ ov.option_type.sku_part, ov.sku_part ] }
        self.sku = sku_parts.flatten.join('-')
      end
    end

    def set_position
      self.update_column(:position, product.variants.maximum(:position).to_i + 1)
    end

		def in_stock_cache_key
		  "variant-#{id}-in_stock"
		end

		def clear_in_stock_cache
		  Rails.cache.delete(in_stock_cache_key)
		end

    def touch_index_page_items
      index_page_items.each { |item| item.touch }
    end

  end
end

require_dependency 'spree/variant/scopes'
