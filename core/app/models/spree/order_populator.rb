module Spree
  class OrderPopulator
    attr_accessor :order, :currency
    attr_reader :errors

    def initialize(order, currency)
      @order = order
      @currency = currency
      @errors = ActiveModel::Errors.new(self)
    end

    #
    # Parameters can be passed using the following possible parameter configurations:
    #
    # * Single variant/quantity pairing
    # +:variants => { variant_id => quantity }+
    #
    # * Multiple products at once
    # +:products => { product_id => variant_id, product_id => variant_id }, :quantity => quantity+
    def populate(from_hash)
      # product_assembly
      options = extract_kit_options(from_hash)
      personalisations = extract_personalisations(from_hash)

      from_hash[:products].each do |product_id,variant_id|
        attempt_cart_add(variant_id, from_hash[:quantity], options, personalisations)
      end if from_hash[:products]

      from_hash[:variants].each do |variant_id, quantity|
        attempt_cart_add(variant_id, quantity, options, personalisations )
      end if from_hash[:variants]

      valid?
    end

    def valid?
      errors.empty?
    end

    private

    # product_assembly
    def extract_kit_options(hash)
      value = hash[:products].delete(:options) rescue nil
      (value || [])
    end

    # This will return an array of hashes incase we have multiple
    # personalisations
    def extract_personalisations(hash)
      # passed in product_personlisation_ids
      # id: 33
      # data: { colour: 'red', initials 'dd' }
      # ->
      # Validate the id 
      #   correct product_id
      #   for the 
      # personalisation_id: 1 ( monogram )
      # product_id: 33 ( zion-lion )
      # prices { 1231 3 }
      # data: { colours => [ 'red', 'blue' , 'orange'] , initials_length => 4 }
      # TODO: do some validations a tthis point
      # based on product_id
      #          colours
      #          number of initials
      # e.g. product.personalisation.validate(properties)
      #[{ 
      #  type: 'monogram',
      #  prices: { 
      #      'GBP' => 750,
      #      'USD' => 1000,
      #      'EUR' => 1000,
      #  },
      #  data: {
      #    colour: 'red',
      #    initials: 'DD' 
      #  }
      #}]
      [
        {
          personalisation_id: 12, 
          prices: { 
            'GBP' => BigDecimal.new('7.50'),
            'USD' => BigDecimal.new('10.00'),
            'EUR' => BigDecimal.new('10.00'),
          },
          data:  { colour: 'red', initials: 'DD'},
        }
      ]
    end

    # This has modifications for options and personalisations
    def attempt_cart_add(variant_id, quantity, option_ids=[], personalisations=[])
      quantity = quantity.to_i
      # 2,147,483,647 is crazy.
      # See issue #2695.
      if quantity > 2_147_483_647
        errors.add(:base, Spree.t(:please_enter_reasonable_quantity, :scope => :order_populator))
        return false
      end
      variant = Spree::Variant.find(variant_id)
      options = Spree::Variant.find(option_ids)
      options_with_qty = add_quantity_for_each_option(variant, options)

      if quantity > 0
        if check_stock_levels_for_variant_and_options(variant, quantity, options_with_qty)
          shipment = nil
          line_item = @order.contents.add(variant, quantity, currency, shipment, options_with_qty, personalisations)
          unless line_item.valid?
            errors.add(:base, line_item.errors.messages.values.join(" "))
            return false
          end
        end
      end
    end

    def check_stock_levels(variant, quantity)
      display_name = %Q{#{variant.name}}
      display_name += %Q{ (#{variant.options_text})} unless variant.options_text.blank?

      if Stock::Quantifier.new(variant).can_supply? quantity
        true
      else
        errors.add(:base, Spree.t(:out_of_stock, :scope => :order_populator, :item => display_name.inspect))
        return false
      end
    end

  end
end
