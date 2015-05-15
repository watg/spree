module Report
  module View
    class SecondOrders

      NAME = "second_orders_view"

      def name
        NAME
      end

      def sql
        "CREATE MATERIALIZED VIEW #{name} as
         SELECT o1.*
         FROM completed_orders_view o1
         INNER JOIN (
           SELECT o2.email email, MIN(o2.completed_at) completed_at
           FROM completed_orders_view o2
           WHERE NOT EXISTS (
               SELECT o3.id
               FROM first_orders_view as o3
               WHERE o2.id = o3.id
           )
           GROUP BY email
         ) AS o4 ON o1.email = o4.email AND o1.completed_at = o4.completed_at"
      end

    end
  end
end
