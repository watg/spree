require 'spec_helper'

describe Spree::IssueGiftCardJob do
  let(:line_item) { create(:line_item, quantity: 1, variant: create(:product, product_type: :gift_card).master) }
  subject { Spree::IssueGiftCardJob.new(line_item.order, line_item, 0) }

  it "uses gift card service" do
    expect(Spree::IssueGiftCardService).
      to receive(:run).
      with(order: line_item.order, line_item: line_item, position: 0).
      and_return(double('outcome', :success? => true))

    subject.perform
  end

  context "failed job" do
    before do
      mock_error = double('error', :message_list => ['bad inputs'])
      allow(Spree::IssueGiftCardService).
        to receive(:run).
        with(order: line_item.order, line_item: line_item, position: 0).
        and_return(double('outcome', :success? => false, :errors => mock_error))
    end

    it "raises error message" do
      expect{subject.perform}.to raise_error
    end

  end
end
