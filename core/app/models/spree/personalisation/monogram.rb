module Spree
  class Personalisation::Monogram < Personalisation

#    has_many :prices, class_name: 'Spree::Price', dependent: :destroy
    #has_many 
    store_accessor :data, :max_initials
    store_accessor :data, :colours
    #
    after_initialize :set_defaults

    DEFAULT_PRICES = {
        'GBP' => BigDecimal.new('7.50'),
        'USD' => BigDecimal.new('10.00'),
        'EUR' => BigDecimal.new('10.00'),
      }

    DEFAULT_DATA = {
      'colours' => [
        (Spree::OptionValue.find_by_name 'midnight-blue').id,
        (Spree::OptionValue.find_by_name 'checkers-tweed').id,
        (Spree::OptionValue.find_by_name 'ruby-red').id,
        (Spree::OptionValue.find_by_name 'ultra-violet').id,
        (Spree::OptionValue.find_by_name 'ivory-white').id,
      ].join(','),
      'max_initials' => 2
    }

    def set_defaults
      self.data ||= DEFAULT_DATA
      self.prices ||= DEFAULT_PRICES
    end

    def selected_data_to_text( selected_data )
      colour = colours.detect{ |c| c.id == selected_data['colour'].to_i }
      "Colour: #{colour.presentation}, Initials: #{selected_data['initials']}"
    end

    def options_text
      "Colours: #{colours.map(&:presentation).join(', ')}\n Max Initials: #{max_initials}"
    end

    def colours
      Spree::OptionValue.find data['colours'].split(',')
    end

    def max_initials
      data['max_initials']
    end

    # TODO: This function should validate the params inputs agains
    # the data to make sure they are valid
    def validate( params )
      params
    end

  end
end
 
