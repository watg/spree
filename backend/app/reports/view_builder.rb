module Report
  class ViewBuilder

    attr_accessor :views

    def self.drop_all
      Report::ViewBuilder.new(
        Report::View::EmailMarketingTypes,
        Report::View::SecondOrders,
        Report::View::FirstOrders,
        Report::View::CompletedOrders
      ).drop
    end

    def self.create_all
      Report::ViewBuilder.new(
        Report::View::CompletedOrders,
        Report::View::FirstOrders,
        Report::View::SecondOrders,
        Report::View::EmailMarketingTypes
      ).create
    end

    def self.refresh_all
      Report::ViewBuilder.new(
        Report::View::CompletedOrders,
        Report::View::FirstOrders,
        Report::View::SecondOrders,
        Report::View::EmailMarketingTypes
      ).refresh
    end

    def initialize(*views)
      @views = views.map(&:new)
    end

    # For completed orders will need to move out
    def create
      views.each do |view|
        create_view(view)
      end
    end

    def refresh
      views.each do |view|
        ActiveRecord::Base.connection.execute("REFRESH MATERIALIZED VIEW #{view.name}")
      end
    end

    def drop
      views.each do |view|
        drop_view(view)
      end
    end

    private

    def create_view(view)
      ActiveRecord::Base.connection.execute(view.sql)
    rescue => e
      if e.to_s.match "PG::DuplicateTable: ERROR"
        puts "views already exist try refreshing the views"
      else
        raise e
      end
    end

    def drop_view(view)
      ActiveRecord::Base.connection.execute("DROP MATERIALIZED VIEW #{view.name}")
    rescue => e
      puts e.inspect
    end

  end
end
