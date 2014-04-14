require 'spec_helper'

describe Spree::BulkOrderPrintingService do
  subject {Spree::BulkOrderPrintingService}
  before :all do
    @unprinted_invoices = 2.times.map { create(:order_ready_to_be_consigned_and_allocated, line_items_count: 2) }
  end

  after :all do
    Spree::Order.delete_all
    Spree::LineItem.delete_all
  end

  before :each do
    allow(Spree::Order).to receive(:unprinted_invoices).and_return(@unprinted_invoices)
  end

  it "generates a PDF for each order that hasn't been printed" do
    expect(Spree::Order).to receive(:unprinted_invoices).and_return(@unprinted_invoices)
    expect_any_instance_of(Spree::PDF::OrdersPrinter).to receive(:print_invoices_and_packing_lists).and_return(:pdf)
    outcome = subject.run(pdf: :invoices)
    expect(outcome).to be_success
    expect(outcome.result).to eq(:pdf)
  end

  it "generates image stickers for each order that hasn't been printed" do
    expect(Spree::Order).to receive(:unprinted_image_stickers).twice.and_return(@unprinted_invoices)
    expect_any_instance_of(Spree::PDF::OrdersPrinter).to receive(:print_stickers).and_return(:pdf)
    outcome = subject.run(pdf: :image_stickers)
    expect(outcome).to be_success
    expect(outcome.result).to eq(:pdf)
  end

  it "allocates a print batch number and date to each order" do
    expect(Spree::Order).to receive(:last_batch_id).and_return(15)
    subject.run(pdf: :invoices)
    @unprinted_invoices.each_with_index do |order, idx|
      expect(order.batch_print_id.to_i).to eq(15 + idx + 1)
      expect(order.batch_invoice_print_date).to eq(Date.today)
    end
  end

  describe "creates print job records" do
    it "when invoices are printed" do
      subject.run(pdf: :invoices)
      job = @unprinted_invoices.first.invoice_print_job
      expect(job.reload.print_time).to be_within(1.second).of(Time.now)
      expect(job.job_type).to eq("invoice")
      expect(job.orders).to match_array(@unprinted_invoices)
    end
  end

  describe "#print_invoices" do
    subject     { Spree::BulkOrderPrintingService.new }
    it "returns a PDF document" do
      expect(subject.send(:print_invoices)[0,4]).to eq('%PDF')
    end
  end


  describe "#print_image_stickers" do
    subject     { Spree::BulkOrderPrintingService.new }
    let(:order) { FactoryGirl.build(:order) }
    before do
      Spree::Order.any_instance.stub_chain(:shipping_address, :firstname, :upcase) { "Person Name" }
      allow(Spree::Order).to receive(:unprinted_image_stickers).and_return([order])
    end
    its(:invoices_have_been_printed?)   { should be_true   }

    it "returns a PDF document" do
      expect(subject.send(:print_image_stickers)[0,4]).to eq('%PDF')
    end

    it "add sticker print date" do
      expect(order).to receive("batch_sticker_print_date=".to_sym)
      subject.send(:print_image_stickers)
    end

    context "invalid call" do
      before do
        allow(Spree::Order).to receive(:unprinted_image_stickers).and_return([])
      end
      its(:invoices_have_been_printed?) { should be_false }
    end

    describe "print job" do
      before do
        Timecop.freeze
        Spree::BulkOrderPrintingService.run(pdf: :image_stickers)
      end

      after do
        Timecop.return
      end

      subject { Spree::PrintJob.last }

      it { should_not be_nil }
      its(:print_time) { should be_within(1.second).of(Time.now) }
      its(:job_type) { should eq("image_sticker") }
      its(:orders) { should eq([order]) }
    end
  end
end
