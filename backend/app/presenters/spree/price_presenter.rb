module Spree
  class PricePresenter< Spree::BasePresenter
    presents :price

    delegate :id, :amount, :sale_amount, :part_amount, :currency, to: :price

    def display_amount
      money(amount)
    end

    def display_sale_amount
      money(sale_amount)
    end

    def display_part_amount
      money(part_amount)
    end

    private

    def money(amount)
      Spree::Price.money(amount,currency)
    end
  end
end