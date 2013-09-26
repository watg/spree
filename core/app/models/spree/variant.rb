module Spree
  class Variant < ActiveRecord::Base
    acts_as_paranoid
    
    belongs_to :product, touch: true, class_name: 'Spree::Product'

    delegate_belongs_to :product, :name, :description, :permalink, :available_on,
                        :tax_category_id, :shipping_category_id, :meta_description,
                        :meta_keywords, :tax_category, :shipping_category

    attr_accessible :name, :presentation, :cost_price, :lock_version,
                    :position, :option_value_ids,
                    :product_id, :option_values_attributes, :price,
                    :weight, :height, :width, :depth, :sku, :cost_currency, :in_sale

    # from variant options
    attr_accessible :option_values
    # end variant options
    
    has_many :inventory_units
    has_many :line_items

    has_many :stock_items, dependent: :destroy
    has_many :stock_locations, through: :stock_items
    has_many :stock_movements


    has_many :displayable_variants 

    has_and_belongs_to_many :option_values, join_table: :spree_option_values_variants
    has_many :images, as: :viewable, order: :position, dependent: :destroy, class_name: "Spree::Image"

    has_one :default_price,
      class_name: 'Spree::Price',
      conditions: proc { { currency: Spree::Config[:currency] } },
      dependent: :destroy

    delegate_belongs_to :default_price, :display_price, :display_amount, :price, :price=, :currency if Spree::Price.table_exists?

    has_many :prices,
      class_name: 'Spree::Price',
      dependent: :destroy

    validate :check_price
    validate :check_prices
    validates :price, numericality: { greater_than_or_equal_to: 0 }, presence: true, if: proc { Spree::Config[:require_master_price] }
    validates :cost_price, numericality: { greater_than_or_equal_to: 0, allow_nil: true } if self.table_exists? && self.column_names.include?('cost_price')

    before_validation :set_cost_currency
    after_create :create_stock_items
    after_create :set_position
    after_save :save_default_price

    # Regardless of us updating anything, touch so we invalidate cache
    after_save { self.touch } 

    # default variant scope only lists non-deleted variants
    scope :deleted, lambda { where("#{Variant.quoted_table_name}.deleted_at IS NOT NULL") }

    scope :not_deleted, lambda { where("#{Variant.quoted_table_name}.deleted_at IS NULL or #{Variant.quoted_table_name}.deleted_at >= ?", Time.zone.now) }

    scope :available, lambda { joins(:product).where("spree_products.available_on <= ?", Time.zone.now)  }

    class << self
      def active(currency = nil)
        joins(:prices).where(deleted_at: nil).where('spree_prices.currency' => currency || Spree::Config[:currency]).where('spree_prices.amount IS NOT NULL')
      end
      
      def displayable(product_id)
        where(product_id: product_id, is_master: false).includes(:displayable_variants)
      end

      def options_by_product(product, option_value_name_list)
        _option_values = Spree::OptionValue.select(:id).where(name: option_value_name_list).all.map(&:id).compact.sort

        product.variants.detect {|v| v.option_values.map(&:id).sort == _option_values}
      end
    end

    def visible?
      displayable_variants.any?
    end

    def cost_price=(price)
      self[:cost_price] = parse_price(price) if price.present?
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
      if self.isa_part?
        types << [:part, :part_sale]
      end
      types.flatten
    end

    def visible_price_types
      price_types - [:part_sale]
    end

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
      find_price(currency_code, :regular) || Spree::Price.new(variant_id: self.id, currency: currency_code, is_kit: false, sale: false)
    end
    def price_normal_sale_in(currency_code)
      find_price(currency_code, :sale) || Spree::Price.new(variant_id: self.id, currency: currency_code, is_kit: false, sale: true)
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
      values = self.option_values.joins(:option_type).order("#{Spree::OptionType.table_name}.position asc")

      values.map! do |ov|
        "#{ov.option_type.presentation}: #{ov.presentation}"
      end

      values.to_sentence({ words_connector: ", ", two_words_connector: ", " })
    end

    def gross_profit
      cost_price.nil? ? 0 : (price - cost_price)
    end

    # use deleted? rather than checking the attribute directly. this
    # allows extensions to override deleted? if they want to provide
    # their own definition.
    def deleted?
      deleted_at
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
          self.product.save
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

    def has_default_price?
      !self.default_price.nil?
    end

    def amount_in(currency)
      price_in(currency).try(:amount)
    end

    def name_and_sku
      "#{name} - #{sku}"
    end

    def in_stock?(quantity=1)
      Spree::Stock::Quantifier.new(self).can_supply?(quantity)
    end

    # Product may be created with deleted_at already set,
    # which would make AR's default finder return nil.
    # This is a stopgap for that little problem.
    def product
      Spree::Product.unscoped { super }
    end

    private
    def find_price(currency, type)
      prices.select{ |price| price.currency == currency && price.sale == (type == :sale) }.first
    end
    
    def find_part_price(currency, type)
      kit_prices.select{ |price| price.currency == currency && price.sale == (type == :sale) }.first 
    end


    def product_price_in(currency)
      self.product.master.prices.select{ |price| price.currency == currency }.first
    end
    
      # strips all non-price-like characters from the price, taking into account locale settings
      def parse_price(price)
        return price unless price.is_a?(String)

        separator, delimiter = I18n.t([:'number.currency.format.separator', :'number.currency.format.delimiter'])
        non_price_characters = /[^0-9\-#{separator}]/
        price.gsub!(non_price_characters, '') # strip everything else first
        price.gsub!(separator, '.') unless separator == '.' # then replace the locale-specific decimal separator with the standard separator if necessary

        price.to_d
      end

      # Ensures a new variant takes the product master price when price is not supplied
      def check_price
        if price.nil? && Spree::Config[:require_master_price]
          raise 'No master variant found to infer price' unless (product && product.master)
          raise 'Must supply price for variant or master.price for product.' if self == product.master
          self.price = product.master.price
        end
        if currency.nil?
          self.currency = Spree::Config[:currency]
        end
      end

      # Ensure all a variant prices inherit the master prices if not supplied, this is very similar to 
      # check_price apart from this looks at the prices table
      def check_prices
        price_hash = {}
        self.prices.each do |p| 
          price_hash[[p.currency,p.is_kit,p.sale]] = p 
        end

        self.product.master.prices.each do |mp| 
          if !price_hash[[mp.currency,mp.is_kit,mp.sale]] or price_hash[[mp.currency,mp.is_kit,mp.sale]].amount < 0.01
            self.prices << mp.dup
          end
        end
      end

      def save_default_price
        default_price.save if default_price && (default_price.changed? || default_price.new_record?)
      end

      def set_cost_currency
        self.cost_currency = Spree::Config[:currency] if cost_currency.nil? || cost_currency.empty?
      end

      def create_stock_items
        Spree::StockLocation.all.each do |stock_location|
          stock_location.stock_items.create!(variant: self, backorderable: stock_location.backorderable_default)
        end
      end

      def set_position
        self.update_column(:position, product.variants.maximum(:position).to_i + 1)
      end
  end
end

require_dependency 'spree/variant/scopes'
