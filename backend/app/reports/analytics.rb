module Report
  class Analytics
    include Spree::BaseReport

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

    LTV_HEADER ||= %w(
      first_purchase_date
      purchase_date
      unique_customers
      purchases
      avg_spend
      total_spend
    )

    RC_HEADER ||= %w(
      first_order_date
      first_order_count
      second_order_count
    )

    def run
      refresh_views
      life_time_value
      returning_customers
    end

    def refresh_views
      Report::ViewBuilder.refresh_all
    end

    def life_time_value
      groups.each do |key, names|
        filename = File.join(Rails.root, "tmp", "ltv_#{key}_#{Date.today}.csv")
        CSV.open(filename, "wb") do |csv|
          csv << LTV_HEADER
          marketing_types = Spree::MarketingType.where(name: names).to_a
          formatted_data_for_life_time_value(marketing_types) do |data|
            csv << data
          end
        end
      end
    end

    def returning_customers
      groups.each do |key, names|
        filename = File.join(Rails.root, "tmp", "rc_#{key}_#{Date.today}.csv")
        CSV.open(filename, "wb") do |csv|
          csv << RC_HEADER
          marketing_types = Spree::MarketingType.where(name: names).to_a
          formatted_data_for_returning_customers(marketing_types) do |data|
            csv << data
          end
        end
      end
    end

    def formatted_data_for_life_time_value(marketing_types)
      data = fetch_data_for_life_time_value(marketing_types)
      format_data_for_life_time_value(normalise_data_for_life_time_value(data)).each do |d|
        yield d
      end
    end

    def formatted_data_for_returning_customers(marketing_types)
      data = fetch_data_for_returning_customers(marketing_types)
      format_data_for_returning_customers(data).each do |d|
        yield d
      end
    end

    private

    def filename_uuid
      "#{@from.to_s(:number)}_#{@to.to_s(:number)}"
    end

    def groups
      GROUPS.merge(all: Spree::MarketingType.all.map(&:name).uniq)
    end

    def fetch_data_for_life_time_value(marketing_types)
      ActiveRecord::Base.connection.execute(life_time_value_sql(marketing_types)).to_a
    end

    def fetch_data_for_returning_customers(marketing_types)
      ActiveRecord::Base.connection.execute(returning_customers_sql(marketing_types)).to_a
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
    def returning_customers_sql(marketing_types)
      "SELECT
  DATE_TRUNC('month', marketing_types.completed_at) first_order_date,
  COUNT(marketing_types.completed_at)::int first_order_count,
  COUNT(second_orders_view.completed_at)::int second_order_count
from
  (#{ email_marketing_types_sql(marketing_types) }) as marketing_types
LEFT OUTER JOIN
  second_orders_view ON marketing_types.email=second_orders_view.email
GROUP BY first_order_date
ORDER BY first_order_date"
    end

    def exchange_rate(currency)
      ActiveRecord::Base.sanitize(Helpers::CurrencyConversion::TO_GBP_RATES[currency])
    end

    def life_time_value_sql(marketing_types)
      "SELECT
  DATE_TRUNC('month', t1.completed_at) first_purchase_date,
  t2.date purchase_date,
  count(t1.email) unique_customers,
  SUM(t2.payment_total) total_spend,
  SUM(t2.purchases) total_purchases
FROM
  (#{ email_marketing_types_sql(marketing_types) }) as t1
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
    FROM completed_orders_view
    GROUP BY email, date
  ) as t2
ON t1.email=t2.email
GROUP BY first_purchase_date, purchase_date
ORDER BY first_purchase_date, purchase_date"
    end

    def email_marketing_types_sql(marketing_types)
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

    def groups
      GROUPS.merge(all: Spree::MarketingType.all.map(&:name).uniq)
    end

  end
end
