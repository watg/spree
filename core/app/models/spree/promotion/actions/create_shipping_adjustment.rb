module Spree
  class Promotion
    module Actions
      # Quick way to distinguish regular adjustment from shipping adjustment
      class CreateShippingAdjustment < CreateAdjustment
      end
    end
  end
end
