module Spree
  class StockCheckAlertJob
    include ActionView::Helpers
    include ActionDispatch::Routing
    include Rails.application.routes.url_helpers

    def initialize(params={})
    end

    def perform
      out_of_stock_items = generate_data
      if out_of_stock_items.any?
        message = format_data_to_string( out_of_stock_items )
        Spree::NotificationMailer.send_notification(message, Rails.application.config.out_of_stock_email_list,'Items out of stock').deliver
      end
    end

    private

    def generate_data
      data = []
      Spree::Variant.includes(:product, stock_items: [:stock_location]).
        merge(Spree::StockLocation.available).
        where(Spree::StockItem.table_name =>{ :updated_at => 1.day.ago .. Time.now} ).
        find_each do |v|
          # we do not want to include master variant if its product has normal variants
          unless v.is_master_but_has_variants?
            data << v unless Spree::Stock::Quantifier.new(v).can_supply? 1
          end
        end

        data.inject({}) do |hash,v|
          hash[v.product.marketing_type.name.to_s] ||= []
          hash[v.product.marketing_type.name.to_s] << v
          hash
        end

    end

    def format_data_to_string(data)
      message = []

      data.each do |marketing_type, variants|
        message << marketing_type
        message << "==========="
        message << ""

        variants.each do |v|
          message << "\t #{v.name}, #{v.sku}, #{url(v.product)}"
        end
        message << ""
        message << ""

      end
      message.join("\n")
    end

    def url(product_id)
      Spree::Core::Engine.routes.url_helpers.stock_admin_product_url(product_id)
    end

  end
end
