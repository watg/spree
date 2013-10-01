module Spree
  class BulkOrderPrintingService < Mutations::Command
    required do
      string :pdf
    end
    
    def execute
      return unless valid_pdf_type?(pdf)
      send("print_#{pdf}".to_sym)
    end

    private
    def valid_pdf_type?(pdf)
      if not [:invoices , :image_stickers].include?(pdf.to_sym)
        add_error(:pdf_name, :unknown_pdf_name, "No defined pdf for #{pdf}")
        return false
      end
      true
    end


    def print_invoices
      orders = Spree::Order.unprinted_invoices
      print_date = Time.now
      last_batch_id = Spree::Order.last_batch_id_today
      orders.each_with_index do |order, idx|
        order.batch_print_id = last_batch_id + idx + 1
        order.batch_invoice_print_date = print_date
        order.save!
      end

      Spree::PDF::OrdersToBeDispatched.orders_to_pdf(orders)
    end

    def print_image_stickers
      return unless invoices_have_been_printed?
      orders = Spree::Order.unprinted_image_stickers
      
      print_date = Time.now
      orders.each_with_index do |order, idx|
        order.batch_sticker_print_date = print_date
        order.save!
      end
      
      Spree::PDF::OrdersToBeDispatched.stickers_to_pdf(orders)
    end

    def invoices_have_been_printed?
      if not Spree::Order.unprinted_image_stickers.any?
        add_error(:image_sticker, :image_sticker_cannot_be_printed, "You must print invoices before printing the image stickers")
        return false
      end
      true
    end
  end
end
