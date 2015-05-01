module ShippingMethodDurations
  module Description
    def static_description
      description(min, max)
    end

    def dynamic_description
      duration_calculator = ShippingMethodDurations::ShippingDurationCalculator.new(self)
      description(duration_calculator.calc_min, duration_calculator.calc_max)
    end

    private

    def description(min, max)
      if max.present? && min.present?
        "#{min}-#{max} business days"
      elsif max.present?
        "up to #{max} business days"
      else
        "in a few days"
      end
    end
  end
end
