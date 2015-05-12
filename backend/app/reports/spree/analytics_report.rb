module Spree
  # This provides the life time value and also basic cohort analysis based aroud marketing type
  # for completed orders
  class AnalyticsReport
    include BaseReport
    # TODO: take into account shipping and promotions
    # periodic job to update the views
    # GROUPS:
    #   0. ALL
    #   1. PERU MADE + GANG MADE
    #   2. KNIT YOUR OWN
    #   3. YARN + ROSEWOOD NEEEDLES + CLASPS + EMBELISHMENTS
    #   4. KNITTING PATTERN
    #   5. RTW + MIX
    #   1,2,3,4,[1,2-4]
    GROUPS ||= {
      rtw: %w(peruvian gang),
      kit: %w(kit kit-crochet),
      sup: %w(yarn needle embellishment clasp),
      pat: %w(pattern)
    }

    COMPLETE_STATES = Spree::Order::COMPLETE_STATES.map {|str| "'#{str}'"}.join(',')

    attr_accessor :marketing_types, :connection

    def initialize(marketing_types)
      @marketing_types = marketing_types || []
      @connection = ActiveRecord::Base.connection.raw_connection
    end

    def self.run_all
      refresh_views
      life_time_value
      returning_customers
    end

    def self.life_time_value
      groups.each do |key, names|
        # Create filename with the group and a date
        obj = init_self_for_marketing_types(names)
        filename = File.join(Rails.root, "tmp", "ltv_#{key}_#{Date.today}.csv")
        CSV.open(filename, "wb") do |csv|
          csv << obj.header_for_life_time_value
          obj.formatted_data_for_life_time_value do |data|
            csv << data
          end
        end
      end
    end

    def self.returning_customers
      groups.each do |key, names|
        # Create filename with the group and a date
        obj = init_self_for_marketing_types(names)
        filename = File.join(Rails.root, "tmp", "rc_#{key}_#{Date.today}.csv")
        CSV.open(filename, "wb") do |csv|
          csv << obj.header_for_returning_customers
          obj.formatted_data_for_returning_customers do |data|
            csv << data
          end
        end
      end
    end

    def self.init_self_for_marketing_types(names)
      marketing_types = Spree::MarketingType.where(name: names).to_a
      new(marketing_types)
    end

    # If there is a problem creating them, then refresh them
    def self.create_views
      ActiveRecord::Base.connection.execute(first_orders_view_sql)
      #connection = ActiveRecord::Base.connection.raw_connection
      #connection.prepare('first_orders_view', first_orders_view_sql)
      #connection.exec_prepared('first_orders_view', [COMPLETE_STATES])
      ActiveRecord::Base.connection.execute(second_orders_view_sql)
      ActiveRecord::Base.connection.execute(email_marketing_types_view_sql)
    rescue => e
      if e.to_s.match "PG::DuplicateTable: ERROR"
        puts "views already exist try refreshing the views"
      else
        raise e
      end
    end

    def self.drop_views
      drop_email_marketing_types_view
      drop_second_orders_view
      drop_first_orders_view
    end

    def self.drop_email_marketing_types_view
      ActiveRecord::Base.connection.execute("DROP MATERIALIZED VIEW email_marketing_types_view")
    rescue => e
      puts e.inspect
    end

    def self.drop_first_orders_view
      ActiveRecord::Base.connection.execute("DROP MATERIALIZED VIEW first_orders_view")
    rescue => e
      puts e.inspect
    end

    def self.drop_second_orders_view
      ActiveRecord::Base.connection.execute("DROP MATERIALIZED VIEW second_orders_view")
    rescue => e
      puts e.inspect
    end

    def self.refresh_views
      ActiveRecord::Base.connection.execute("REFRESH MATERIALIZED VIEW first_orders_view")
      ActiveRecord::Base.connection.execute("REFRESH MATERIALIZED VIEW second_orders_view")
      ActiveRecord::Base.connection.execute("REFRESH MATERIALIZED VIEW email_marketing_types_view")
    end

    def header_for_life_time_value
      %w(
        first_purchase_date
        purchase_date
        unique_customers
        purchases
        avg_spend
        total_spend
      )
    end

    def header_for_returning_customers
      %w(
        first_order_date
        first_order_count
        second_order_count
      )
    end

    def formatted_data_for_life_time_value
      data = fetch_data_for_life_time_value
      format_data_for_life_time_value(normalise_data_for_life_time_value(data)).each do |d|
        yield d
      end
    end

    def formatted_data_for_returning_customers
      data = fetch_data_for_returning_customers
      format_data_for_returning_customers(data).each do |d|
        yield d
      end
    end

    private

    def filename_uuid
      "#{@from.to_s(:number)}_#{@to.to_s(:number)}"
    end

    def self.groups
      GROUPS.merge(all: Spree::MarketingType.all.map(&:name).uniq)
    end

    def fetch_data_for_life_time_value
      ActiveRecord::Base.connection.execute(life_time_value_sql).to_a
    end

    def fetch_data_for_returning_customers
      ActiveRecord::Base.connection.execute(returning_customers_sql).to_a
    end

    def normalise_data_for_life_time_value(data)
      # Normalise the amounts to GBP
      data.each_with_object({}) do |r, hash|
        key = [r["first_purchase_date"], r["purchase_date"]]
        hash[key] ||= {}
        hash[key]["unique_customers"] ||= 0
        hash[key]["unique_customers"] += r["unique_customers"].to_i
        hash[key]["total_purchases"] ||= 0
        hash[key]["total_purchases"] += r["total_purchases"].to_i
        hash[key]["total_spend"] ||= 0.00
        hash[key]["total_spend"] += r["total_spend"].to_f
      end
    end

    def format_data_for_life_time_value(hash)
      # Format it into one nice big array
      hash.map do |dates, prices|
        dates + prices.values
      end
    end

    def format_data_for_returning_customers(data)
      data.map do |record|
        [record["first_order_date"], record["first_order_count"], record["second_order_count"]]
      end
    end

    # Of all the people that made at least 1 order for the given marketing type
    # Return the month in which they made that first purchase, the date and also
    # the date they made the second purchase
    # Then group by month to give us the quantity of first purchases followed by
    # how many repeated
    def returning_customers_sql
      "SELECT
  DATE_TRUNC('month', marketing_types.completed_at) first_order_date,
  COUNT(marketing_types.completed_at)::int first_order_count,
  COUNT(second_orders_view.completed_at)::int second_order_count
from
  (#{ email_marketing_types_sql }) as marketing_types
LEFT OUTER JOIN
  second_orders_view ON marketing_types.email=second_orders_view.email
GROUP BY first_order_date
ORDER BY first_order_date"
    end

    def exchange_rate(currency)
      ActiveRecord::Base.sanitize(Helpers::CurrencyConversion::TO_GBP_RATES[currency])
    end

    def life_time_value_sql
      "SELECT
  DATE_TRUNC('month', t1.completed_at) first_purchase_date,
  t2.date purchase_date,
  count(t1.email) unique_customers,
  SUM(t2.payment_total) total_spend,
  SUM(t2.purchases) total_purchases
from
  (#{ email_marketing_types_sql }) as t1
LEFT OUTER JOIN
  (
    SELECT
      email, DATE_TRUNC('month', completed_at) date,
      SUM(
        CASE WHEN currency='GBP' THEN (payment_total)::float *#{exchange_rate('GBP')}
             WHEN currency='USD' THEN (payment_total)::float *#{exchange_rate('USD')}
             WHEN currency='EUR' THEN (payment_total)::float *#{exchange_rate('EUR')}
        END
      ) payment_total,
      COUNT(email) purchases
    FROM spree_orders o
    INNER JOIN spree_order_types ot on o.order_type_id=ot.id
    INNER JOIN spree_payments p on p.order_id=o.id
    INNER JOIN spree_payment_methods pm on p.payment_method_id=pm.id
    WHERE completed_at IS NOT NULL
    AND state in (#{COMPLETE_STATES})
    AND pm.name IN ('Credit Card', 'PayPal')
    AND ot.name = 'regular'
    GROUP BY email, date
  ) as t2
ON t1.email=t2.email
GROUP BY first_purchase_date, purchase_date
ORDER BY first_purchase_date, purchase_date"
    end

    def email_marketing_types_sql
      marketing_type_ids = marketing_types.map(&:id)
      marketing_type_ids_string = marketing_type_ids.join(",").to_s

      not_exists_sql = "SELECT email
    FROM email_marketing_types_view
    WHERE marketing_type_id IN
    (
      SELECT id from spree_marketing_types
      WHERE id NOT IN(#{marketing_type_ids_string})
    )
    GROUP BY email"

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

    def self.email_marketing_types_view_sql
      "CREATE MATERIALIZED VIEW email_marketing_types_view as
SELECT pr.marketing_type_id marketing_type_id, o.email email, MIN(completed_at) completed_at
FROM spree_line_items li
INNER JOIN first_orders_view o on li.order_id=o.id
INNER JOIN spree_order_types ot on o.order_type_id=ot.id
INNER JOIN spree_variants v ON li.variant_id = v.id
INNER JOIN spree_products pr ON v.product_id = pr.id
INNER JOIN spree_payments p on p.order_id=o.id
INNER JOIN spree_payment_methods pm on p.payment_method_id=pm.id
WHERE o.completed_at is not null
AND o.state in (#{COMPLETE_STATES})
AND pm.name IN ('Credit Card', 'PayPal')
AND ot.name = 'regular'
GROUP BY marketing_type_id, email"
    end

    def self.first_orders_view_sql
      "CREATE MATERIALIZED VIEW first_orders_view as
  SELECT o1.*
  FROM spree_orders o1
  INNER JOIN spree_order_types ot1 on o1.order_type_id=ot1.id
  INNER JOIN spree_payments p1 on p1.order_id=o1.id
  INNER JOIN spree_payment_methods pm1 on p1.payment_method_id=pm1.id
  INNER JOIN (
    SELECT email, MIN(completed_at) completed_at
    FROM spree_orders o
    INNER JOIN spree_order_types ot2 on o.order_type_id=ot2.id
    INNER JOIN spree_payments p2 on p2.order_id=o.id
    INNER JOIN spree_payment_methods pm2 on p2.payment_method_id=pm2.id
    WHERE completed_at is not null
    AND state in (#{COMPLETE_STATES})
    AND pm2.name IN ('Credit Card', 'PayPal')
    AND ot2.name = 'regular'
    GROUP BY email
  ) AS o2 ON o1.email = o2.email AND o1.completed_at = o2.completed_at
    WHERE ot1.name = 'regular'
    AND pm1.name IN ('Credit Card', 'PayPal')"
    end

    def self.second_orders_view_sql
      "CREATE MATERIALIZED VIEW second_orders_view as
  SELECT o1.*
  FROM spree_orders o1
  INNER JOIN spree_order_types ot1 on o1.order_type_id=ot1.id
  INNER JOIN spree_payments p1 on p1.order_id=o1.id
  INNER JOIN spree_payment_methods pm1 on p1.payment_method_id=pm1.id
  INNER JOIN (
    SELECT o2.email email, MIN(o2.completed_at) completed_at
    FROM spree_orders o2
    INNER JOIN spree_order_types ot2 on o2.order_type_id=ot2.id
    INNER JOIN spree_payments p2 on p2.order_id=o2.id
    INNER JOIN spree_payment_methods pm2 on p2.payment_method_id=pm2.id
    WHERE NOT EXISTS
    (
      SELECT o3.id
      FROM first_orders_view as o3
      WHERE o2.id = o3.id
    )
    AND o2.completed_at is not null
    AND o2.state in (#{COMPLETE_STATES})
    AND pm2.name IN ('Credit Card', 'PayPal')
    AND ot2.name = 'regular'
    GROUP BY email
  ) AS o4 ON o1.email = o4.email AND o1.completed_at = o4.completed_at
    WHERE ot1.name = 'regular'
    AND pm1.name IN ('Credit Card', 'PayPal')"
    end
  end
end
