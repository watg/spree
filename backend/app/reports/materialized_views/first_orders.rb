module Report
  module View
    class FirstOrders

      NAME = "first_orders_view"

      def name
        NAME
      end

      def sql
        "CREATE MATERIALIZED VIEW #{name} as
         SELECT o1.*
         FROM completed_orders_view o1
         INNER JOIN (
           SELECT o.email, MIN(o.completed_at) completed_at
           FROM completed_orders_view AS o
           GROUP BY o.email
         ) AS o2 ON o1.email = o2.email AND o1.completed_at = o2.completed_at"
      end

    end
  end
end
