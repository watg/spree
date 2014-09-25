module Spree
  class BulkOrderPrintingService
    extend ActiveModel::Naming

    attr_accessor :name
    attr_reader   :errors, :result

    BATCH_SIZE = 25

    def initialize
      @errors = ActiveModel::Errors.new(self)
    end

    def valid?
      errors.empty?
    end


    def print_invoices(orders=nil)
      orders = orders.first(BATCH_SIZE)
      print_date = Time.now
      print_job = Spree::PrintJob.create!(job_type: :invoice)

      last_batch_id = Spree::Order.last_batch_id
      orders.each_with_index do |order, idx|
        order.batch_print_id = last_batch_id + idx + 1
        order.batch_invoice_print_date = print_date
        order.invoice_print_job = print_job
        order.save!
      end

      @result = print_job.pdf

      self
    end

    def print_image_stickers(orders)
      if invoices_have_been_printed?(orders)
        orders = orders.first(BATCH_SIZE)
        print_date = Time.now

        print_job = Spree::PrintJob.create!(job_type: :image_sticker)

        orders.each_with_index do |order, idx|
          order.batch_sticker_print_date = print_date
          order.image_sticker_print_job = print_job
          order.save!
        end

        @result = print_job.pdf
      end

      self
    end

    def self.human_attribute_name(attr, options = {})
      attr
    end

  private
    def invoices_have_been_printed?(orders)
      if orders.empty?
        errors.add(:image_sticker, "You must print invoices before printing the image stickers")
        return false
      end
      true
    end
  end
end
