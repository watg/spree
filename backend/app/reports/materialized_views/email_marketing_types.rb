module Report
  module View
    class EmailMarketingTypes

      NAME = "email_marketing_types_view"

      def name
        NAME
      end

      def sql
        "CREATE MATERIALIZED VIEW #{name} as
           SELECT pr.marketing_type_id marketing_type_id, o.email email,
             MIN(completed_at) completed_at
           FROM spree_line_items li
           INNER JOIN first_orders_view o on li.order_id=o.id
           INNER JOIN spree_order_types ot on o.order_type_id=ot.id
           INNER JOIN spree_variants v ON li.variant_id = v.id
           INNER JOIN spree_products pr ON v.product_id = pr.id
           INNER JOIN spree_payments p on p.order_id=o.id
           INNER JOIN spree_payment_methods pm on p.payment_method_id=pm.id
           GROUP BY marketing_type_id, email"
      end

    end
  end
end


