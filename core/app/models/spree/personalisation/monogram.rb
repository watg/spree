module Spree
  class Personalisation::Monogram < Personalisation

    store_accessor :data, :max_initials
    store_accessor :data, :colours
    after_initialize :set_defaults

    DEFAULT_PRICES = {
        'GBP' => BigDecimal.new('7.50'),
        'USD' => BigDecimal.new('10.00'),
        'EUR' => BigDecimal.new('10.00'),
      }

    DEFAULT_COLOURS = [ 'midnight-blue', 'checkers-tweed', 'ruby-red', 'ultra-violet', 'ivory-white', 'highlighter-yellow', 'fluoro-pink' ]

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

    private

    def set_defaults
      self.data ||= default_data
      self.prices ||= DEFAULT_PRICES
    end

    def default_data
      @default_data ||= {
        'colours' => DEFAULT_COLOURS.map do |c| 
          o = Spree::OptionValue.find_by_name c 
          !o.nil? ? o.id : nil
        end.compact.join(','),
        'max_initials' => 2
      }
    end

  end
end
 
