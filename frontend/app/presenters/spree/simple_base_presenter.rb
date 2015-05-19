module Spree
  # to inherit from when a presenter does not necessarily accept an object
  class SimpleBasePresenter
    def initialize(view_context)
      @view_context = view_context
    end

    def present
      yield self if block_given?
    end

    def device
      h.device
    end

    def currency
      h.current_currency
    end

    def country_code
      h.current_country_code
    end

    private

    def h
      @view_context
    end
  end
end
