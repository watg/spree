module Admin
  class ShippingMethodDurationPresenter < Spree::BasePresenter
    using ShippingMethodDurations::Description
    presents :shipping_method_duration
    delegate :id, :max, :min, to: :shipping_method_duration

    def self.model_name
      Spree::ShippingMethodDuration.model_name
    end

    def static_description
      @object.static_description
    end

    def dynamic_description
      @object.dynamic_description
    end
  end
end
