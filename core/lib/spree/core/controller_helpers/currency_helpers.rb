module Spree
  module Core
    module ControllerHelpers
      module CurrencyHelpers
        extend ActiveSupport::Concern
        
        included do
          helper_method :supported_currencies
        end
        
        def supported_currencies
          Spree::Config[:supported_currencies].split(',').map { |code| ::Money::Currency.find(code) }
        end
      end
    end
  end
end
