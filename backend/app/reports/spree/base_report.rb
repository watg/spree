module Spree
  module BaseReport

    def filename
      "#{name}.#{filename_uuid}.csv"
    end

    def name
      self.class.to_s.split('::').last.underscore
    end

  end
end
