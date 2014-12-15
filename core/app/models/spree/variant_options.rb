module Spree
  class VariantOptions

    attr_reader :variants, :currency, :items, :option_types, :option_values, :displayable_option_type

    def initialize(variants, currency, displayable_option_type = nil)
      @variants = variants
      @currency = currency
      @displayable_option_type = displayable_option_type
      build
    end

    def tree
      variants.inject({}) do |hash, variant|
        base = create_options_base(hash, variant)
        add_generic_details_to_base(base, variant)
        add_image_to_base(base, variant)
        add_prices_to_base(base, variant)
        add_supplier_to_base(base, variant)
        add_total_on_hand_to_base(base, variant)
        hash
      end
    end

    def simple_tree
      variants.inject({}) do |hash, variant|
        base = create_options_base(hash, variant)
        add_generic_details_to_base(base, variant)
        add_prices_to_base(base, variant)
        add_image_to_base(base, variant)
        hash
      end
    end

    # This does not need to be targetted as you can not have variants without
    # populating each of the option types
    def option_type_order
      hash = {}
      option_type_names = option_types.order(:position).map{|o| o.url_safe_name}
      option_type_names.each_with_index { |o,i| hash[o] = option_type_names[i+1] }
      hash
    end

    def option_values_in_stock
      items_in_stock.map(&:value).uniq
    end

    def variant_option_values
      items_in_stock.inject({}) do |hash, item|
        hash[item.variant.number] ||= []
        hash[item.variant.number] << [ item.type.url_safe_name, item.value.url_safe_name ]
        hash
      end
    end

    def grouped_option_values_in_stock
      return @grouped_option_values_in_stock if @grouped_option_values_in_stock
      rtn = items_in_stock.group_by(&:type).inject({}) do |hash,(type,options)|
        hash[type] = options.map { |o| o.value }.uniq.sort { |a| a.position }
        hash
      end
      @grouped_option_values_in_stock ||= rtn
    end

    def option_types_and_values_for(variant)
      items = find(variant)
      items.map{ |item| [ item.type.url_safe_name, item.value.url_safe_name, item.value.presentation] }
    end

    private

    def prices
      @prices ||= Spree::Price.where(variant_id: variants, currency: currency)
    end

    def images
      @images ||= Spree::Image.where(viewable_id: variants, viewable_type: 'Spree::Variant')
    end

    def stock_items
      @stock_items ||= Spree::StockItem.joins(:stock_location).where(variant_id: variants).includes(:supplier).references(:supplier).merge(StockLocation.available)
    end

    def items_in_stock
      @items_in_stock ||= items.select { |item| item.variant.in_stock_cache? }
    end

    def create_options_base(existing_hash, variant)
      find(variant).inject(existing_hash) do |base, option|
        base[option.type.url_safe_name] ||= {}
        base[option.type.url_safe_name][option.value.url_safe_name] ||= {}
        base = base[option.type.url_safe_name][option.value.url_safe_name]
        base
      end
    end

    def add_generic_details_to_base(base, variant)
      base['variant'] ||= {}
      base['variant']['id'] = variant.id
      base['variant']['in_stock'] = variant.in_stock_cache
      base['variant']['number'] = variant.number
    end

    def add_prices_to_base(base, variant)
      variant_prices = prices.select { |p| p.variant_id == variant.id }

      base['variant']['normal_price'] = normal_price(variant_prices)
      base['variant']['sale_price'] = sale_price(variant_prices)
      base['variant']['part_price'] = part_price(variant_prices)
      base['variant']['in_sale'] = variant.in_sale
    end

    def add_supplier_to_base(base, variant)
      variant_stock_items = stock_items.select { |s| s.variant_id == variant.id }
      suppliers = variant_stock_items.map(&:supplier).uniq
      base['variant']['suppliers'] = suppliers
    end

    def add_total_on_hand_to_base(base, variant)
      variant_stock_items = stock_items.select { |s| s.variant_id == variant.id }
      base['variant']['total_on_hand'] = variant.total_on_hand(variant_stock_items)
    end

    def add_image_to_base(base,variant)
      variant_images = images.select { |i| i.viewable_id == variant.id }
      if variant_images.any?
        base['variant']['image_url'] = variant_images.first.attachment.url(:mini)
      end
    end

    def variant_stock_items(variant)
      if @variant_stock_items && @variant_stock_items[variant.id]
        return @variant_stock_items[variant.id]
      end
      @variant_stock_items ||= stock_items.select { |s| s.variant_id == variant.id }
    end

    def part_price(variant_prices)
      if price = Spree::Price.find_part_price(variant_prices, currency)
        price.in_subunit
      else
        0
      end
    end

    def sale_price(variant_prices)
      if price = Spree::Price.find_sale_price(variant_prices, currency)
        price.in_subunit
      else
        0
      end
    end

    def normal_price(variant_prices)
      if price = Spree::Price.find_normal_price(variant_prices, currency)
        price.in_subunit
      else
        0
      end
    end

    Item = Struct.new(:variant, :value, :type)

    def build
      option_values_variants = Spree::OptionValuesVariant.joins(option_value: [:option_type]).where(variant_id: variants)

      if displayable_option_type
        option_values_variants = option_values_variants.where("spree_option_types.id = ?", displayable_option_type.id)
      end

      option_value_ids = option_values_variants.map { |ovv| ovv.option_value_id }.uniq
      @option_values = Spree::OptionValue.where(id: option_value_ids)
      @option_types = Spree::OptionType.where(id: option_values.map { |ov| ov.option_type_id}.uniq )

      @items = option_values_variants.map do |ovv|
        variant = variants.detect { |v| v.id == ovv.variant_id }
        option_value = option_values.detect { |ov| ov.id == ovv.option_value_id }
        option_type = option_types.detect { |ot| ot.id == option_value.option_type_id }

        Item.new(variant, option_value, option_type)
      end

      @items.sort! { |a,b| [a.type.position, a.value.position ] <=> [b.type.position, b.value.position ] }
    end

    def find(variant)
      items.select { |item| item.variant == variant }
    end

  end
end
