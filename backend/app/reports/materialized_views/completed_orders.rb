module Report
  module View
    class CompletedOrders

      NAME = "completed_orders_view"

      def name
        NAME
      end

      def sql
        "CREATE MATERIALIZED VIEW #{name} as #{completed_orders_sql}"
      end
      
      private

      def completed_orders_sql
        Report::Query::CompletedOrders.new.sql
      end

    end
  end
end
