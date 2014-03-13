# PRODUCTS
# Products represent an entity for sale in a store.
# Products can have variations, called variants
# Products properties include description, permalink, availability,
#   shipping category, etc. that do not change by variant.
#
# MASTER VARIANT
# Every product has one master variant, which stores master price and sku, size and weight, etc.
# The master variant does not have option values associated with it.
# Price, SKU, size, weight, etc. are all delegated to the master variant.
# Contains on_hand inventory levels only when there are no variants for the product.
#
# VARIANTS
# All variants can access the product properties directly (via reverse delegation).
# Inventory units are tied to Variant.
# The master variant can have inventory units, but not option values.
# All other variants have option values and may have inventory units.
# Sum of on_hand each variant's inventory level determine "on_hand" level for the product.
#

module Spree
  class Product < ActiveRecord::Base
    acts_as_paranoid

    NATURE = {
      physical: [:kit, :product, :virtual_product, :pattern, :parcel, :made_by_the_gang, :accessory],
      digital:  [:gift_card] } unless defined?(NATURE)

    has_many :product_option_types, dependent: :destroy
    has_many :option_types, through: :product_option_types
    has_many :visible_option_types, -> { where spree_product_option_types: true }, through: :product_option_types

    has_many :product_properties, dependent: :destroy
    has_many :properties, through: :product_properties

    has_many :displayable_variants

    has_many :classifications, dependent: :delete_all
    has_many :taxons, through: :classifications
    has_and_belongs_to_many :promotion_rules, join_table: :spree_products_promotion_rules

    has_many :product_targets, class_name: 'Spree::ProductTarget', dependent: :destroy
    has_many :targets, class_name: 'Spree::Target', through: :product_targets

    belongs_to :tax_category,      class_name: 'Spree::TaxCategory'
    belongs_to :shipping_category, class_name: 'Spree::ShippingCategory'
    belongs_to :gang_member,       class_name: 'Spree::GangMember'
    belongs_to :product_group,     class_name: 'Spree::ProductGroup', touch: true

    belongs_to :martin_type, class_name: 'Spree::MartinProductType'

    validates :product_group, :presence => true
    validates :gang_member, :presence => true

    has_many :personalisations, dependent: :destroy

    has_many :assembly_definitions, -> { order "position" }, class_name: "Spree::AssemblyDefinition", foreign_key: :assembly_id

    has_one :master,
      -> { where is_master: true },
      inverse_of: :product,
      class_name: 'Spree::Variant',
      dependent: :destroy

    has_many :variants,
      -> { where(is_master: false).order("#{::Spree::Variant.quoted_table_name}.position ASC") },
      inverse_of: :product,
      class_name: 'Spree::Variant'

    has_many :variants_including_master,
      -> { order("#{::Spree::Variant.quoted_table_name}.position ASC") },
      inverse_of: :product,
      class_name: 'Spree::Variant',
      dependent: :destroy

    has_many :all_variants_unscoped, class_name: 'Spree::Variant'

    has_many :prices, -> { order('spree_variants.position, spree_variants.id, currency') }, through: :variants

    has_many :stock_items, through: :variants_including_master

    delegate_belongs_to :master, :sku, :price, :currency, :display_amount, :display_price, :weight, :height, :width, :depth, :is_master, :has_default_price?, :cost_currency, :price_in, :price_normal_in, :amount_in
    delegate_belongs_to :master, :cost_price if Variant.table_exists? && Variant.column_names.include?('cost_price')

    after_create :set_master_variant_defaults
    after_create :add_properties_and_option_types_from_prototype
    after_create :build_variants_from_option_values_hash, if: :option_values_hash

    after_save :save_master

    delegate :images, to: :master, prefix: true
    alias_method :images, :master_images

    delegate :assembly_definition, to: :master

    has_many :variant_images, -> { order(:position) }, source: :images, through: :variants_including_master
    has_many :target_images, -> { select('spree_assets.*, spree_variant_targets.variant_id, spree_variant_targets.target_id').order(:position) }, source: :target_images, through: :variants_including_master
    has_many :personalisation_images, -> { order(:position) }, source: :images, through: :personalisations

     # Hack for the old pages, remove once the new pages are live
    def variant_images_including_targetted
      @_images_including_targetted ||= [self.variant_images, self.target_images].flatten.sort_by { |i| i.position }
    end

    accepts_nested_attributes_for :variants, allow_destroy: true
    accepts_nested_attributes_for :product_targets, allow_destroy: true

    validates :name, presence: true
    validates :permalink, presence: true
    validates :shipping_category_id, presence: true

    attr_accessor :option_values_hash

    accepts_nested_attributes_for :product_properties, allow_destroy: true, reject_if: lambda { |pp| pp[:property_name].blank? }

    make_permalink order: :name

    alias :options :product_option_types

    after_initialize :ensure_master

    def self.types
      NATURE.values.flatten
    end

    def nature
      return :digital if (NATURE[:digital].include?(product_type) || NATURE[:digital].include?(product_type.to_sym))
      :physical
    end

    def memoized_gang_member
      @_memoized_gang_member ||= gang_member
    end

    def memoized_images
      @_memoized_images ||= images
    end

    def memoized_variant_images
      @_memoized_variant_images ||= variant_images
    end

    def next_variant_in_stock
      variants.in_stock.active(currency).includes(:product).references(:product).first
    end

    def lowest_priced_variant(currency, in_sale: false )
      all_variants_or_master.lowest_priced_variant(currency, in_sale: in_sale)
    end

    def variants_in_stock
      self.variants.in_stock
    end

    def variant_and_target_images
      (memoized_variant_images + target_images).sort_by(&:position)
    end

    def images_for(target)
      return memoized_variant_images unless target
      targeted_images = target_images.where("spree_variant_targets.target_id = ?", target.id)
      (targeted_images + memoized_variant_images).sort_by(&:position)
    end

    def description_for(target)
      return description unless target
      product_target = product_targets.find_by(target_id: target.id)
      return description unless product_target
      product_target.description
    end

    def first_variant_or_master
      variants[0] || master
    end

    def all_variants_or_master
      variants.blank? ? Spree::Variant.where(is_master: true, product_id: self.id) : variants
    end

    def option_values
      option_values_for(nil)
    end

    def option_values_for(target)
      check_stock = true
      selector = Spree::OptionValue.for_product(self,check_stock).includes(:option_type).joins(:option_type)
      selector = selector.with_target(target) if target.present?
      @_option_values ||= selector.reorder( "spree_option_types.position", "spree_option_values.position" )
    end

    def grouped_option_values
      @_option_values ||= option_values.group_by(&:option_type)
    end

    def grouped_option_values_for(target)
      @_grouped_option_values ||= option_values_for(target).group_by(&:option_type)
    end

    def variants_for_option_value(value)
      @_variant_option_values ||= variants.includes(:option_values)
      @_variant_option_values.select { |i| i.option_value_ids.include?(value.id) }
    end

    def variants_with_only_master
      ActiveSupport::Deprecation.warn("[SPREE] Spree::Product#variants_with_only_master will be deprecated in Spree 1.3. Please use Spree::Product#master instead.")
      master
    end
    before_destroy :punch_permalink

    def visible_option_types
      option_types.where('spree_product_option_types.visible' => true)
    end

    def to_param
      permalink.present? ? permalink : (permalink_was || name.to_s.to_url)
    end

    # the master variant is not a member of the variants array
    def has_variants?
      variants.any?
    end

    def tax_category
      if self[:tax_category_id].nil?
        TaxCategory.where(is_default: true).first
      else
        TaxCategory.find(self[:tax_category_id])
      end
    end

    # Adding properties and option types on creation based on a chosen prototype
    attr_reader :prototype_id
    def prototype_id=(value)
      @prototype_id = value.to_i
    end

    # Ensures option_types and product_option_types exist for keys in option_values_hash
    def ensure_option_types_exist_for_values_hash
      return if option_values_hash.nil?
      option_values_hash.keys.map(&:to_i).each do |id|
        self.option_type_ids << id unless option_type_ids.include?(id)
        product_option_types.create(option_type_id: id) unless product_option_types.pluck(:option_type_id).include?(id)
      end
    end

    # for adding products which are closely related to existing ones
    # define "duplicate_extra" for site-specific actions, eg for additional fields
    def duplicate
      duplicator = ProductDuplicator.new(self)
      duplicator.duplicate
    end

    # use deleted? rather than checking the attribute directly. this
    # allows extensions to override deleted? if they want to provide
    # their own definition.
    def deleted?
      !!deleted_at
    end

    def available?
      !(available_on.nil? || available_on.future?)
    end

    # split variants list into hash which shows mapping of opt value onto matching variants
    # eg categorise_variants_from_option(color) => {"red" -> [...], "blue" -> [...]}
    def categorise_variants_from_option(opt_type)
      return {} unless option_types.include?(opt_type)
      variants.active.group_by { |v| v.option_values.detect { |o| o.option_type == opt_type} }
    end

    def name_and_type
      "#{name} - #{product_type}"
    end

    def self.saleable?
      where(individual_sale: true)
    end

    def self.like_any(fields, values)
      where fields.map { |field|
        values.map { |value|
          arel_table[field].matches("%#{value}%")
        }.inject(:or)
      }.inject(:or)
    end

    # Suitable for displaying only variants that has at least one option value.
    # There may be scenarios where an option type is removed and along with it
    # all option values. At that point all variants associated with only those
    # values should not be displayed to frontend users. Otherwise it breaks the
    # idea of having variants
    def variants_and_option_values(current_currency = nil)
      variants.includes(:option_values).active(current_currency).select do |variant|
        variant.option_values.any?
      end
    end

    def empty_option_values?
      options.empty? || options.any? do |opt|
        opt.option_type.option_values.empty?
      end
    end

    def property(property_name)
      return nil unless prop = properties.find_by(name: property_name)
      product_properties.find_by(property: prop).try(:value)
    end

    def set_property(property_name, property_value)
      ActiveRecord::Base.transaction do
        # Works around spree_i18n #301
        property = if Property.exists?(name: property_name)
          Property.where(name: property_name).first
        else
          Property.create(name: property_name, presentation: property_name)
        end
        product_property = ProductProperty.where(product: self, property: property).first_or_initialize
        product_property.value = property_value
        product_property.save!
      end
    end

    def possible_promotions
      promotion_ids = promotion_rules.map(&:activator_id).uniq
      Spree::Promotion.advertised.where(id: promotion_ids).reject(&:expired?)
    end

    def total_on_hand
      if self.variants_including_master.any? { |v| !v.should_track_inventory? }
        Float::INFINITY
      else
        self.stock_items.sum(&:count_on_hand)
      end
    end

    # Master variant may be deleted (i.e. when the product is deleted)
    # which would make AR's default finder return nil.
    # This is a stopgap for that little problem.
    def master
      super || variants_including_master.with_deleted.where(is_master: true).first
    end

    def variants_for(target)
      if !target.blank?
        variants.joins(:variant_targets).where("spree_variant_targets.target_id = ?", target.id)
      else
        variants
      end
    end

    def variant_options_tree_for(target, current_currency)
      variants.options_tree_for(target, current_currency)
    end

    # Need to retire once the new product_pages are live
    def variant_options_tree(current_currency)
      variant_options_tree_for(nil,current_currency)
    end

    # This does not need to be targetted as you can not have variants without
    # populating each of the option types
    def option_type_order
      hash = {}
      option_type_names = self.option_types.order(:position).map{|o| o.url_safe_name}
      option_type_names.each_with_index { |o,i| hash[o] = option_type_names[i+1] }
      hash
    end

    private
    # Builds variants from a hash of option types & values
    def build_variants_from_option_values_hash
      ensure_option_types_exist_for_values_hash
      values = option_values_hash.values
      values = values.inject(values.shift) { |memo, value| memo.product(value).map(&:flatten) }

      values.each do |ids|
        variants.create(
          option_value_ids: ids,
          prices: master.prices
        )
      end
      save
    end

    def add_properties_and_option_types_from_prototype
      if prototype_id && prototype = Spree::Prototype.find_by(id: prototype_id)
        prototype.properties.each do |property|
          product_properties.create(property: property)
        end
        self.option_types = prototype.option_types
      end
    end

    # ensures the master variant is flagged as such
    def set_master_variant_defaults
      master.is_master = true
    end

    # there's a weird quirk with the delegate stuff that does not automatically save the delegate object
    # when saving so we force a save using a hook.
    def save_master
      if master && (master.changed? ||  master.new_record? )
        master.save
      end
    end

    def ensure_master
      return unless new_record?
      self.master ||= Variant.new
    end

    def punch_permalink
      update_attribute :permalink, "#{Time.now.to_i}_#{permalink}" # punch permalink with date prefix
    end
  end
end

require_dependency 'spree/product/scopes'
