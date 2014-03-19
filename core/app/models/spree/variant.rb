module Spree
  class Variant < ActiveRecord::Base
    acts_as_paranoid

    belongs_to :product, touch: true, class_name: 'Spree::Product'

    delegate_belongs_to :product, :name, :description, :permalink, :available_on,
                        :tax_category_id, :shipping_category_id, :meta_description,
                        :meta_keywords, :tax_category, :shipping_category

    has_many :inventory_units
    has_many :line_items

    has_many :stock_items, dependent: :destroy
    has_many :stock_locations, through: :stock_items
    has_many :stock_movements
    has_many :displayable_variants

    has_and_belongs_to_many :option_values, join_table: :spree_option_values_variants, class_name: "Spree::OptionValue"
    has_many :images, -> { order(:position) }, as: :viewable, dependent: :destroy, class_name: "Spree::Image"
    # PArt of the image work that needs to be done
    # has_many :assembly_defintition_images, -> { order(:position) }, as: :viewable, dependent: :destroy, class_name: "Spree::Image"

    has_many :variant_targets, class_name: 'Spree::VariantTarget', dependent: :destroy
    has_many :target_images, -> { select('spree_assets.*, spree_variant_targets.variant_id, spree_variant_targets.target_id').order(:position) }, source: :images, through: :variant_targets
    has_many :targets, class_name: 'Spree::Target', through: :variant_targets

    has_many :assembly_definition_variants, class_name: 'Spree::AssemblyDefinitionVariant'

     # Hack for the old pages, remove once the new pages are live
    def images_including_targetted
      @_images_including_targetted ||= [self.images, self.target_images].flatten.sort_by { |i| i.position }
    end

    has_one :default_price,
      -> { where currency: Spree::Config[:currency] },
      class_name: 'Spree::Price',
      dependent: :destroy

    delegate_belongs_to :default_price, :display_price, :display_amount, :price, :price=, :currency
    
    delegate_belongs_to :product, :assembly_definitions

    has_many :prices,
      class_name: 'Spree::Price',
      dependent: :destroy

    validates :cost_price, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
    validate :variant_weight

    has_many :taggings, as: :taggable
    has_many :tags, -> { order(:value) }, through: :taggings

    has_many :index_page_items

    has_one :assembly_definition

    before_validation :set_cost_currency
    before_validation :generate_variant_number, on: :create

    after_create :create_stock_items
    after_create :set_position
    after_create :create_assembly_definition_if_kit
    after_touch :touch_index_page_items

    # This can take a while so run it asnyc with a low priority for now
    after_touch { delay(:priority => 20).touch_assemblies_parts if self.assemblies.any? }

    has_many :assembly_products ,-> { uniq }, through: :assembly_definition_variants
    after_save { delay(:priority => 20 ).touch_assembly_products if assembly_products.any? }

    # default variant scope only lists non-deleted variants
    scope :deleted, lambda { where.not(deleted_at: nil) }

    scope :not_deleted, lambda { where("#{Variant.quoted_table_name}.deleted_at IS NULL or #{Variant.quoted_table_name}.deleted_at >= ?", Time.zone.now) }

    scope :available, lambda { joins(:product).where("spree_products.available_on <= ?", Time.zone.now)  }

    scope :in_stock, lambda { where(in_stock_cache: true) }

    NUMBER_PREFIX = 'V'

    class << self
      def physical
        includes(:product).where('spree_products.product_type' => Spree::Product::NATURE[:physical])
      end

      def digital
        includes(:product).where('spree_products.product_type' => Spree::Product::NATURE[:digital])
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

      def options_tree_for(target, current_currency)
        selector = self.includes(:normal_prices, :kit_prices, :images, :option_values => [:option_type])
        if !target.blank?
          selector = selector.joins(:variant_targets).where("spree_variant_targets.target_id = ?", target.id)
        end

        variants = selector.order( "spree_option_types.position", "spree_option_values.position" )

        # Preprocess the variants to remove any option_types that only have 1 option value
        #valid_option_types = {}
        #variants.each do |v| 
        #  v.option_values.each do |ov| 
        #    valid_option_types[ov.option_type.name] ||= Set.new
        #    valid_option_types[ov.option_type.name] << ov.name 
        #  end
        #end
        #valid_option_types.keep_if { |k,set| set.size > 1 }

        hash={}
        variants.each do |v|
          base=hash
          v.option_values.each_with_index do |o,i|
            #next unless valid_option_types.has_key? o.option_type.name 
            base[o.option_type.url_safe_name] ||= {}
            base[o.option_type.url_safe_name][o.url_safe_name] ||= {}
            base = base[o.option_type.url_safe_name][o.url_safe_name]
          end
          base['variant'] ||= {}
          base['variant']['id']=v.id
          base['variant']['normal_price']=v.price_normal_in(current_currency).in_subunit
          base['variant']['sale_price']=v.price_normal_sale_in(current_currency).in_subunit
          base['variant']['part_price']=v.price_part_in(current_currency).in_subunit
          base['variant']['in_sale']=v.in_sale
          base['variant']['in_stock']= v.in_stock_cache 
          if v.images.any?
            base['variant']['image_url']= v.images.first.attachment.url(:mini)
          end
        end
        hash
      end

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
      !variant_id.match(/^#{NUMBER_PREFIX}\d+/).nil?
    end

    def images_for(target)
      return images unless target

      variant_target = variant_targets.where(target_id: target.id).first
      targeted_images = variant_target ? variant_target.images : []
      (targeted_images + images).sort_by(&:position)
    end

    def visible?
      displayable_variants.any?
    end

    def weight
      return static_kit_weight if self.assemblies_parts.any?
      return dynamic_kit_weight if self.assembly_definition
      basic_weight(super)
    end

    def static_kit_weight
      kit_weight = required_parts_for_display.inject(0.00) do |sum,part|
        count_part = part.count_part 
        part_weight = part.weight 
        notify("Variant id #{part.id} has no weight") unless part_weight
        sum + (count_part * part_weight)
      end
      BigDecimal.new(kit_weight,2)
    end
    
    def dynamic_kit_weight
      warning = "Only use this variant#dynamic_kit_weight to get kit weight right. Not suitable for getting kit weight of past orders"
      Rails.logger.info(warning)
      puts(warning)

      self.assembly_definition.parts.where(optional: false).reduce(BigDecimal(0,2)) do |part_total_weight, part|
        first_available_variant = part.variants.detect {|v| v.weight && v.weight > 0 }
        variant_weight = first_available_variant.try(:weight)
        notify("Variant id #{first_available_variant.id} has no weight") unless variant_weight
        part_total_weight + ( part.count * variant_weight )
      end
    end
    
    def basic_weight(value_from_super_weight)
      return value_from_super_weight if self.is_master || self.new_record?

      if (value_from_super_weight.blank? || value_from_super_weight.zero?)
        value = if self.product
                  self.product.master.weight
                else
                  nil 
                end
        notify("The weight of variant id: #{self.id} is nil.\nThe weight of product id: #{self.product.try(:id)}") unless value
        value
      else
        value_from_super_weight
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
      if self.isa_part?
        types << [:part, :part_sale]
      end
      types.flatten
    end

    def visible_price_types
      price_types - [:part_sale]
    end

    # Hacks to allow the tests to still pass
    #############################################
    def price
      current_price_in( Spree::Config[:currency] ).amount
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
      values = self.option_values.joins(:option_type).order("#{Spree::OptionType.table_name}.position asc")

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
      deleted_at
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

    def in_stock?(quantity=1)
      Spree::Stock::Quantifier.new(self).can_supply?(quantity)
    end

    def out_of_stock?(quantity=1)
      !in_stock?(quantity)
    end

    def sku_and_options_text
      "#{sku} #{options_text}".strip
    end

    # Product may be created with deleted_at already set,
    # which would make AR's default finder return nil.
    # This is a stopgap for that little problem.
    def product
      Spree::Product.unscoped { super }
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
    def variant_weight
      if not (self.product && self.product.product_type == 'kit')
        errors.add(:weight, 'must be greater than 0') if (self.weight.blank? || self.weight <= 0)
      end
    end
    def notify(msg)
      # Sends an email to Techadmin
      NotificationMailer.send_notification(msg)
    end

    def touch_assembly_products
      assembly_products.map(&:touch)
    end

    def create_assembly_definition_if_kit
      if self.isa_kit?
        if self.assembly_definition.nil?
          Spree::AssemblyDefinition.create variant_id: self.id
        end
      end
    end

    def find_normal_price(currency, type)
      normal_prices.select{ |price| price.currency == currency && price.sale == (type == :sale) }.first
    end

    def find_part_price(currency, type)
      kit_prices.select{ |price| price.currency == currency && price.sale == (type == :sale) }.first
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

    def set_cost_currency
      self.cost_currency = Spree::Config[:currency] if cost_currency.nil? || cost_currency.empty?
    end

    def create_stock_items
      StockLocation.all.each do |stock_location|
        stock_location.propagate_variant(self) if stock_location.propagate_all_variants?
      end
    end

    def set_position
      self.update_column(:position, product.variants.maximum(:position).to_i + 1)
    end

    def touch_index_page_items
      index_page_items.each { |item| item.touch }
    end
  end
end

require_dependency 'spree/variant/scopes'
