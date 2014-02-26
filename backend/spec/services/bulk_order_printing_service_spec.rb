require 'spec_helper'

describe Spree::BulkOrderPrintingService do
  subject {Spree::BulkOrderPrintingService}
  let(:unprinted_invoices) { 2.times.map { FactoryGirl.create(:order_ready_to_be_consigned_and_allocated) }.sort! }

  before :each do
    allow(Spree::Order).to receive(:unprinted_invoices).and_return(unprinted_invoices)
    allow(Spree::Order).to receive(:last_batch_id).and_return(0)
    allow(Spree::PDF::OrdersToBeDispatched).to receive(:orders_to_pdf)
  end

  it "generates a PDF for each order that hasn't been printed" do
    expect(Spree::Order).to receive(:unprinted_invoices).and_return(unprinted_invoices)
    expect(Spree::PDF::OrdersToBeDispatched).to receive(:orders_to_pdf).
      with(unprinted_invoices.sort!).
      and_return(:pdf)
    outcome = subject.run(pdf: :invoices)
    puts outcome.inspect
    puts outcome.errors.inspect
    expect(outcome).to be_success
    expect(outcome.result).to eq(:pdf)
  end

  it "generates a image stickers for each order that hasn't been printed" do
    expect(Spree::Order).to receive(:unprinted_image_stickers).twice.and_return(unprinted_invoices)
    expect(Spree::PDF::OrdersToBeDispatched).to receive(:stickers_to_pdf).
      with(unprinted_invoices.to_a.sort!).
      and_return(:pdf)
    outcome = subject.run(pdf: :image_stickers)
    expect(outcome).to be_success
    expect(outcome.result).to eq(:pdf)
  end

  it "allocates a print batch number and date to each order" do
    Timecop.freeze do
      subject.run(pdf: :invoices)
      unprinted_invoices.each_with_index do |order, idx|
        order.reload
        expect(order.batch_print_id.to_i).to eq(idx + 1)
        expect(order.batch_invoice_print_date).to eq(Date.today)
      end
    end
  end

  describe "print job" do
    before do
      Timecop.freeze
      Spree::BulkOrderPrintingService.run(pdf: :invoices)
    end

    after do
      Timecop.return
    end

    subject { Spree::PrintJob.last }

    it { should_not be_nil }
    its(:print_time) { should be_within(1.second).of(Time.now) }
    its(:job_type) { should eq("invoice") }
    its(:orders) { should match_array(unprinted_invoices) }
  end

  it "keeps batch numbers unique each day" do
    Time.zone = 'UTC'
    Timecop.freeze(Date.today) do
      expect(Spree::Order).to receive(:last_batch_id).and_return(15)
      subject.run(pdf: :invoices)
      unprinted_invoices.each_with_index do |order, idx|
        order.reload
        expect(order.batch_print_id.to_i).to eq(15 + idx + 1)
        expect(order.batch_invoice_print_date).to eq(Date.today)
      end
    end
  end


  describe "#print_image_stickers" do
    subject     { Spree::BulkOrderPrintingService.new }
    let(:order) { FactoryGirl.build(:order) }
    before do
      allow(Spree::Order).to receive(:unprinted_image_stickers).and_return([order])
      allow(Spree::PDF::OrdersToBeDispatched).to receive(:stickers_to_pdf).and_return(:pdf)
    end
    its(:invoices_have_been_printed?)   { should be_true   }
    its(:print_image_stickers)          { should eql(:pdf) }
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
