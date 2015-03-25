module Spree
  # Provide a way to categorise orders into different types, this is useful for an all manner of
  # things from reporting to modifiying the behaviour of an order
  class OrderType < ActiveRecord::Base
    REGULAR = 'regular'
    PARTY = 'party'

    class << self
      def regular
        where(name: REGULAR).first
      end

      def party
        where(name: PARTY).first
      end
    end

    def regular?
      name == REGULAR
    end

    def party?
      name == PARTY
    end
  end
end
