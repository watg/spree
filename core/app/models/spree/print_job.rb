module Spree
  class PrintJob < ActiveRecord::Base
    has_many :invoice_orders, foreign_key: 'invoice_print_job_id', class_name: "Spree::Order"
    has_many :image_sticker_orders, foreign_key: 'image_sticker_print_job_id', class_name: "Spree::Order"

    before_create :set_print_time

    def orders
      if invoice?
        invoice_orders.not_cancelled
      elsif image_sticker?
        image_sticker_orders.not_cancelled
      end
    end

    def pdf
      if invoice?

        orders_printer = Spree::PDF::OrdersPrinter.new(orders)

        # none will be returned and errors will be assigned if an error occurs
        printed_invoices = orders_printer.print_invoices_and_packing_lists

        orders_printer.errors.each do |msg|
          self.errors.add(:base, msg)
        end

        printed_invoices

      elsif image_sticker?
        Spree::PDF::OrdersPrinter.new(orders).print_stickers
      end
    end

    private

    def invoice?
      self.job_type.to_sym == :invoice
    end

    def image_sticker?
      self.job_type.to_sym == :image_sticker
    end

    def set_print_time
      self.print_time ||= Time.now
    end
  end
end
