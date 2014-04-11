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
        NotificationMailer.send_notification(message, 'david@woolandthegang.com','Items out of stock')
      end
    end

    private

    def generate_data
      data = []
      Spree::Variant.includes(:product, stock_items: [:stock_location]).
        where(Spree::StockLocation.table_name =>{ :active => true} ).
        where(Spree::StockItem.table_name =>{ :updated_at => 1.day.ago .. Time.now} ).
        find_each do |v|
          data << v unless Spree::Stock::Quantifier.new(v, v.stock_items).can_supply? 1
        end

        data.inject({}) do |hash,v|
          hash[v.product.product_type.to_s] ||= []
          hash[v.product.product_type.to_s] << v
          hash
        end

    end

    def format_data_to_string(data)
      message = []

      data.each do |product_type, variants|
        message << product_type
        message << "==========="
        message << ""

        variants.each do |v|
          message << "\t #{v.name}, #{v.sku} , #{url(v.product)}"
        end
        message << ""
        message << ""

      end
      message.join("\n")
    end

    def url(product_id)
      Spree::Core::Engine.routes.url_helpers.stock_admin_product_url(product_id, host: Rails.application.routes.url_helpers.root_url)
    end

  end
end
