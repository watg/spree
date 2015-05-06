module ShippingMethodDurations
  # Calculates the min and max of a shipping duration with holidays
  class ShippingDurationCalculator
    attr_reader :use_holidays, :shipping_method_duration

    def initialize(duration)
      @shipping_method_duration = duration
      @use_holidays = use_holidays
    end

    def calc_max
      raw_max + Holidays::UKHolidays.holidays_in(raw_max).size if raw_max.present?
    end

    def calc_min
      raw_min + Holidays::UKHolidays.holidays_in(raw_min).size if raw_min.present?
    end

    private

    def raw_max
      shipping_method_duration.max
    end

    def raw_min
      shipping_method_duration.min
    end
  end
end
