module Admin
  class ShippingMethodDurationPresenter < Spree::BasePresenter
    presents :shipping_method_duration

    delegate :id, :max, :min, :static_description, :dynamic_description, to: :shipping_method_duration
    def initialize(object, template, context={})
      super(object, template, context)
      object.extend(ShippingMethodDurations::Description)
    end

    def self.model_name
      Spree::ShippingMethodDuration.model_name
    end

  end
end
