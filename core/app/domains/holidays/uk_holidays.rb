module Holidays
  # Uk public holidays feeder
  module UKHolidays
    def self.holidays_in(days)
      range = Date.today..(Date.today + days.to_i)
      holidays_in = holidays.map do |holiday|
        holiday if range.include? Date.parse(holiday["date"])
      end
      holidays_in.reject(&:nil?)
    end

    def self.holidays
      response = Rails.cache.fetch("bank-holidays", expires_in: 12.hours) do
        JSON.parse(RestClient.get("https://www.gov.uk/bank-holidays.json"))
      end
      response = response["england-and-wales"]["events"]
    rescue
      response = []
    ensure
      response
    end
  end
end
