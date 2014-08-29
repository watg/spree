module Spree
  class BulkOrderPrintingService < ActiveInteraction::Base

    BATCH_SIZE = 25

    symbol :pdf

    def execute
      return unless valid_pdf_type?(pdf)
      send("print_#{pdf}".to_sym)
    end

    private
    def valid_pdf_type?(pdf)
      if not [:invoices , :image_stickers].include?(pdf.to_sym)
        errors.add(:pdf_name, "No defined pdf for #{pdf}")
        return false
      end
      true
    end


    def print_invoices
      orders = Spree::Order.unprinted_invoices.first(BATCH_SIZE)
      print_date = Time.now

      print_job = Spree::PrintJob.create!(job_type: :invoice)

      last_batch_id = Spree::Order.last_batch_id
      orders.each_with_index do |order, idx|
        order.batch_print_id = last_batch_id + idx + 1
        order.batch_invoice_print_date = print_date
        order.invoice_print_job = print_job
        order.save!
      end

      print_job.pdf
    end

    def print_image_stickers
      return unless invoices_have_been_printed?
      orders = Spree::Order.unprinted_image_stickers.first(BATCH_SIZE)
      print_date = Time.now

      print_job = Spree::PrintJob.create!(job_type: :image_sticker)

      orders.each_with_index do |order, idx|
        order.batch_sticker_print_date = print_date
        order.image_sticker_print_job = print_job
        order.save!
      end

      print_job.pdf
    end

    def invoices_have_been_printed?
      if not Spree::Order.unprinted_image_stickers.any?
        errors.add(:image_sticker, "You must print invoices before printing the image stickers")
        return false
      end
      true
    end
  end
end
