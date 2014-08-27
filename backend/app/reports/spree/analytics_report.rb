module Spree
  class AnalyticsReport
    include BaseReport

    # It is gang or peru not gang and peru
    # TODO take into account shipping and promotions
    # periodic job to update the views

    def initialize(marketing_types)
      @marketing_types = marketing_types || []
    end

    def self.create_views
      ActiveRecord::Base.connection.execute(first_orders_view_sql)
      ActiveRecord::Base.connection.execute(email_marketing_types_view_sql)
    end

    def self.delete_views
    end

    def self.refresh_views
    end

    def filename_uuid
      "#{@from.to_s(:number)}_#{@to.to_s(:number)}"
    end

    def header
      %w(
        first_purchase_date
        purchase_date
        purchases
        avg_spend
        total_spend
      )
    end

    def retrieve_data
      sql = life_time_value_sql(@marketing_types)
      data = ActiveRecord::Base.connection.execute(sql).to_a
      format_data( normalise_data(data) ).each do |d|
        yield d
      end
    end

    def generate_csv
      CSV.generate do |csv|
        csv << header
        retrieve_data do |data|
          csv << data
        end
      end
    end

    private

    def life_time_value_sql(marketing_types)
      "SELECT
  DATE_TRUNC('month', t1.completed_at) first_purchase_date,
  t2.date purchase_date,
  t2.currency currency,
  SUM(t2.item_total) total_spend,
  SUM(t2.purchases) total_purchases,
  SUM(t2.item_total) / SUM(t2.purchases) avg_spend
from
  (#{ email_marketing_types_sql(marketing_types) }) as t1
LEFT OUTER JOIN
  (
    SELECT
      email, DATE_TRUNC('month', completed_at) date,
      SUM(item_total) item_total, 
      currency,
      COUNT(email) purchases
    FROM spree_orders
    WHERE completed_at IS NOT NULL 
    AND email <> 'request@woolandthegang.com'
    GROUP BY email, date, currency
  ) as t2
ON t1.email=t2.email
GROUP BY first_purchase_date, purchase_date, currency
ORDER BY first_purchase_date, purchase_date, currency "
    end

    def normalise_data(data)

      # Normalise the amounts to GBP
      hash = data.inject({}) do |hash,r|
        key = [ r["first_purchase_date"], r["purchase_date"] ]
        hash[key] ||= {}
        hash[key]['total_purchases'] ||= 0
        hash[key]['total_purchases'] += r["total_purchases"].to_i
        hash[key]['avg_spend'] ||= 0
        hash[key]['avg_spend'] += xe(r["avg_spend"], r["currency"])
        hash[key]['total_spend'] ||= 0
        hash[key]['total_spend'] += xe(r["total_spend"], r["currency"])
        hash
      end

    end

    def format_data(hash)
      # Format it into one nice big array
      hash.map do |dates,prices|
        dates += prices.values
      end
    end

    def email_marketing_types_sql(marketing_types)

      marketing_type_ids = marketing_types.map(&:id)
      marketing_type_ids_string = marketing_type_ids.join(',').to_s

      not_exists_sql = "SELECT email
    FROM email_marketing_types_view
    WHERE marketing_type_id IN
    (
      SELECT id from spree_marketing_types
      WHERE id NOT IN(#{marketing_type_ids_string})
    )
    GROUP BY email"

      join_sql = []
      marketing_type_ids.each_with_index do |mt_id,i|
        join_sql << "INNER JOIN 
      (
        SELECT email
        FROM email_marketing_types_view
        WHERE marketing_type_id=#{mt_id}
      ) emtv_#{i} ON emtv_#{i}.email=emtv.email
        "
      end

      sql = "SELECT emtv.email email, MIN(emtv.completed_at) completed_at
    FROM email_marketing_types_view emtv
    WHERE NOT EXISTS
    (
      SELECT email
      FROM ( #{not_exists_sql} ) not_exists
      WHERE not_exists.email=emtv.email
    )
    GROUP BY emtv.email"

      sql
    end

    # exchanges to GBP
    def xe(price,currency)
      rates = {'GBP' => 1, 'USD' => 0.61, 'EUR' => 0.83}
      (price.to_f * rates[currency]).to_f
    end

    def self.email_marketing_types_view_sql
      "CREATE OR REPLACE VIEW email_marketing_types_view as
SELECT p.marketing_type_id marketing_type_id, o.email email, MIN(completed_at) completed_at
FROM spree_line_items li
INNER JOIN first_orders_view o on li.order_id=o.id
INNER JOIN spree_variants v ON li.variant_id = v.id
INNER JOIN spree_products p ON v.product_id = p.id
WHERE o.completed_at is not null
AND o.email <> 'request@woolandthegang.com'
GROUP BY marketing_type_id, email"
    end

    def self.first_orders_view_sql
      "CREATE OR REPLACE VIEW first_orders_view as
  SELECT o1.*
  FROM spree_orders o1
  INNER JOIN (
    SELECT email, MIN(completed_at) completed_at
    FROM spree_orders
    WHERE completed_at is not null
    AND email <> 'request@woolandthegang.com'
    GROUP BY email
  ) AS o2 ON o1.email = o2.email AND o1.completed_at = o2.completed_at"
    end

  end
end
