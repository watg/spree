module Spree
  module BaseReport

    def filename
      "#{name}.#{filename_uuid}.csv"
    end

    def name
      self.class.to_s.split('::').last.underscore
    end

    def generate_csv
      CSV.generate do |csv|
        csv << header
        retrieve_data do |data|
          csv << data
        end
      end
    end

  end
end
