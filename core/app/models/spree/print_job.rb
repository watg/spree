module Spree
  class PrintJob < ActiveRecord::Base
    has_many :invoice_orders, foreign_key: 'invoice_print_job_id', class_name: "Spree::Order"
    has_many :image_sticker_orders, foreign_key: 'image_sticker_print_job_id', class_name: "Spree::Order"

    before_create :set_print_time

    def orders
      if invoice?
        invoice_orders
      elsif image_sticker?
        image_sticker_orders
      end
    end

    def pdf
      if invoice?
        Spree::PDF::OrdersPrinter.new(orders).print_invoices_and_packing_lists
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
