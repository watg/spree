module Holidays
  # Uk public holidays feeder
  class UKHolidays
    def self.holidays_in(days)
      range = Date.today..(Date.today + days.to_i)
      holidays_in = holidays.map do |holiday|
        holiday if range.include? Date.parse(holiday["date"])
      end
      holidays_in.reject(&:nil?)
    end

    def self.holidays
      response = JSON.parse(RestClient.get("https://www.gov.uk/bank-holidays.json"))
      response = response["england-and-wales"]["events"]
    rescue
      response = []
    ensure
      response
    end
  end
end
