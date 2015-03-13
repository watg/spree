require 'spec_helper'

describe Spree::BulkOrderPrintingService do
  subject { Spree::BulkOrderPrintingService.new }

  describe "#print_invoices" do
    before :all do
      @unprinted_invoices = 2.times.map { create(:order_ready_to_be_consigned_and_allocated, :with_product_group) }

    end

    it "generates a PDF for each order that hasn't been printed and create a print job" do
      outcome = subject.print_invoices(@unprinted_invoices)
      expect(outcome.valid?).to be true
      expect(outcome.result[0,4]).to eq('%PDF')

      job = @unprinted_invoices.first.invoice_print_job
      expect(job.reload.print_time).to be_within(1.second).of(Time.now)
      expect(job.job_type).to eq("invoice")
      expect(job.orders).to match_array(@unprinted_invoices)
    end

    it "allocates a print batch number and date to each order" do
      expect(Spree::Order).to receive(:last_batch_id).and_return(15)
      subject.print_invoices(@unprinted_invoices)

      @unprinted_invoices.each_with_index do |order, idx|
        expect(order.batch_print_id.to_i).to eq(15 + idx + 1)
        expect(order.batch_invoice_print_date).to eq(Date.today)
      end
    end
  end


  describe "#print_image_stickers" do
    let(:orders) { [FactoryGirl.build(:order)] }

    before do
      Spree::Order.any_instance.stub_chain(:shipping_address, :firstname, :upcase) { "Person Name" }
    end

    it "generates image stickers and adds sticker print date" do
      outcome = subject.print_image_stickers(orders)
      expect(outcome.valid?).to be true
      expect(outcome.result[0,4]).to eq('%PDF')

      expect(orders.first.batch_sticker_print_date).to eq(Date.today)
    end

    it "checks if invoices have been printed" do
      result = subject.send(:invoices_have_been_printed?, [])
      expect(result).to be false

      result = subject.send(:invoices_have_been_printed?, orders)
      expect(result).to be true
    end

    describe "print job" do
      before do
        Spree::BulkOrderPrintingService.new.print_image_stickers(orders)
        Timecop.freeze
      end

      after do
        Timecop.return
      end

      subject { Spree::PrintJob.last }

      it { should_not be_nil }
      its(:print_time) { should be_within(1.second).of(Time.now) }
      its(:job_type) { should eq("image_sticker") }
      its(:orders) { should eq(orders) }
    end
  end
end
