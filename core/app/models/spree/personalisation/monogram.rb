module Spree
  class Personalisation::Monogram < Personalisation

    DEFAULT_PRICES = {
        'GBP' => BigDecimal.new('7.50'),
        'USD' => BigDecimal.new('10.00'),
        'EUR' => BigDecimal.new('10.00'),
      }

    DEFAULT_DATA = {
      colours: [
        (Spree::OptionValue.find_by_name 'midnight-blue').id,
        (Spree::OptionValue.find_by_name 'checkers-tweed').id,
        (Spree::OptionValue.find_by_name 'ruby-red').id,
        (Spree::OptionValue.find_by_name 'ultra-violet').id,
        (Spree::OptionValue.find_by_name 'ivory-white').id,
      ],
      initials: 2
    }

    def prices
      super || DEFAULT_PRICES
    end

    def data
      super || DEFAULT_DATA
    end

    def colours
      #data[:colours].map{ |id|  Spree::OptionValue.find id }
      Spree::OptionValue.find data[:colours]
    end

    def initials
      data[:initials]
    end

    # TODO: This function should validate the params inputs agains
    # the data to make sure they are valid
    def validate( params )
      params
    end

  end
end
 
