module Spree
  class Personalisation::Dob < Personalisation

    store_accessor :data, :max_characters
    store_accessor :data, :colours
    after_initialize :set_defaults

    DEFAULT_PRICES = {
        'GBP' => BigDecimal.new('7.50'),
        'USD' => BigDecimal.new('10.00'),
        'EUR' => BigDecimal.new('10.00'),
      }

    DEFAULT_COLOURS = [ 'midnight-blue', 'checkers-tweed', 'ruby-red', 'ultra-violet', 'ivory-white', 'highlighter-yellow', 'fluoro-pink' ]

    DEFAULT_MAX_CHARACTERS = 10 #19-02-1978

    def selected_data_to_text( selected_data )
      colour = colours.detect{ |c| c.id == selected_data['colour'].to_i }
      "Colour: #{colour.presentation}, Text: #{selected_data['characters']}"
    end

    def options_text
      "Colours: #{colours.map(&:presentation).join(', ')}\n Max Characters: #{max_characters}"
    end


    def colours
      Spree::OptionValue.find data['colours'].split(',')
    end

    def max_characters
      data['max_characters']
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
        'max_characters' => DEFAULT_MAX_CHARACTERS 
      }
    end

  end
end
 
