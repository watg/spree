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
    has_many :product_option_types, dependent: :destroy
    has_many :option_types, through: :product_option_types
    has_many :visible_option_types, -> { where spree_product_option_types: true }, through: :product_option_types

    has_many :product_properties, dependent: :destroy
    has_many :properties, through: :product_properties

    has_many :displayable_variants

    has_many :classifications, dependent: :delete_all
    has_many :taxons, through: :classifications
    has_and_belongs_to_many :promotion_rules, join_table: :spree_products_promotion_rules

    belongs_to :tax_category,      class_name: 'Spree::TaxCategory'
    belongs_to :shipping_category, class_name: 'Spree::ShippingCategory'
    belongs_to :gang_member,       class_name: 'Spree::GangMember'
    belongs_to :product_group,     class_name: 'Spree::ProductGroup'

  
    # ---- from marketplace ext --
    belongs_to :product_group
    belongs_to :gang_member

    validates :product_group, :presence => true
    validates :gang_member, :presence => true
    # ----- end marketplace -------


    has_one :master,
      -> { where is_master: true },
      class_name: 'Spree::Variant',
      dependent: :destroy

    has_many :variants,
      -> { where(is_master: false).order("#{::Spree::Variant.quoted_table_name}.position ASC") },
      class_name: 'Spree::Variant'

    has_many :variants_including_master,
      -> { order("#{::Spree::Variant.quoted_table_name}.position ASC") },
      class_name: 'Spree::Variant',
      dependent: :destroy

    has_many :prices, -> { order('spree_variants.position, spree_variants.id, currency') }, through: :variants

    has_many :stock_items, through: :variants_including_master

    delegate_belongs_to :master, :sku, :price, :currency, :display_amount, :display_price, :weight, :height, :width, :depth, :is_master, :has_default_price?, :cost_currency, :price_in, :price_normal_in, :amount_in
    delegate_belongs_to :master, :cost_price if Variant.table_exists? && Variant.column_names.include?('cost_price')

    after_create :set_master_variant_defaults
    after_create :add_properties_and_option_types_from_prototype
    after_create :build_variants_from_option_values_hash, if: :option_values_hash

    after_save :save_master

    # This will help us clear the caches if a product is modified
    after_touch { self.delay.touch_taxons }

    delegate :images, to: :master, prefix: true
    alias_method :images, :master_images

    has_many :variant_images, -> { order(:position) }, source: :images, through: :variants_including_master

    accepts_nested_attributes_for :variants, allow_destroy: true

    validates :name, presence: true
    validates :permalink, presence: true
    validates :shipping_category_id, presence: true

    attr_accessor :option_values_hash

    accepts_nested_attributes_for :product_properties, allow_destroy: true, reject_if: lambda { |pp| pp[:property_name].blank? }

    make_permalink order: :name

    alias :options :product_option_types

    after_initialize :ensure_master


    def first_variant_or_master
      variants[0] || master
    end

    # from variant options
    def option_values
      @_option_values ||= Spree::OptionValue.for_product(self).order(:position).sort_by {|ov| ov.option_type.position }
    end

    def grouped_option_values
      @_grouped_option_values ||= option_values.group_by(&:option_type)
    end

    def variants_for_option_value(value)
      @_variant_option_values ||= variants.includes(:option_values)
      @_variant_option_values.select { |i| i.option_value_ids.include?(value.id) }
    end

    def variant_options_hash(currency = Spree::Config[:currency])
      return @_variant_options_hash if @_variant_options_hash
      hash = {}
      variants.includes(:option_values).each do |variant|
        variant.option_values.each do |ov|
          otid = ov.option_type_id.to_s
          ovid = ov.id.to_s
          hash[otid] ||= {}
          hash[otid][ovid] ||= {}
          hash[otid][ovid][variant.id.to_s] = variant.to_hash(currency)
        end
      end
      @_variant_options_hash = hash
    end
    # end variant options


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
      if Spree::Config.track_inventory_levels
        self.stock_items.sum(&:count_on_hand)
      else
        Float::INFINITY
      end
    end

    # Master variant may be deleted (i.e. when the product is deleted)
    # which would make AR's default finder return nil.
    # This is a stopgap for that little problem.
    def master
      super || variants_including_master.with_deleted.where(is_master: true).first
    end

    def variant_options_tree(current_currency)
      hash={}
      variants.each do |v|
        base=hash
        v.option_values.order(:position).sort_by {|ov| ov.option_type.position }.each_with_index do |o,i|
          base[o.option_type.url_safe_name] ||= {}
          base[o.option_type.url_safe_name][o.url_safe_name] ||= {}
          if ( i + 1 < v.option_values.size )
            base = base[o.option_type.url_safe_name][o.url_safe_name]
          else
            base[o.option_type.url_safe_name][o.url_safe_name]['variant'] ||= {}
            base[o.option_type.url_safe_name][o.url_safe_name]['variant']['id']=v.id
            base[o.option_type.url_safe_name][o.url_safe_name]['variant']['normal_price']=v.price_normal_in(current_currency).in_subunit
            base[o.option_type.url_safe_name][o.url_safe_name]['variant']['sale_price']=v.price_normal_sale_in(current_currency).in_subunit
            base[o.option_type.url_safe_name][o.url_safe_name]['variant']['in_sale']=v.in_sale
          end
        end
      end
      hash
    end

    def option_type_order
      hash = {}
      option_type_names = self.option_types.order(:position).map{|o| o.url_safe_name}
      option_type_names.each_with_index { |o,i| hash[o] = option_type_names[i+1] }
      hash
    end

    private
    def touch_taxons
      # You should be able to just call self.taxons.each { |t| t.touch } but
      # for some reason acts_as_nested_set does not walk all the ancestors
      # correclty
      self.taxons.each { |t| t.self_and_parents.each { |t2| t2.touch } }
    end

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
