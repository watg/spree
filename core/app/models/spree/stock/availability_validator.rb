module Spree
  module Stock
    class AvailabilityValidator < ActiveModel::Validator

      def validate(line_item)
        quantifier = Stock::Quantifier.new(line_item.variant_id)

        unless quantifier.can_supply? line_item.quantity
          line_item.errors[:quantity] << Spree.t('validation.exceeds_available_stock')
        end

      end
    end
  end
end
