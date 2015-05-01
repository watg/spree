module Spree
  class ShippingMethodDuration < ActiveRecord::Base
    has_many :shipping_methods, class_name: 'Spree::ShippingMethod', foreign_key: :shipping_method_duration_id

    #TODO REMOVE THIS
    def description
      ""
    end

  end
end