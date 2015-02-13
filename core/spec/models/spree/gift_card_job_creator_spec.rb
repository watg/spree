require 'spec_helper'
require 'spree/issue_gift_card_job'

describe Spree::GiftCardJobCreator do
  let(:order) { create(:order) }

  subject(:creator) { Spree::GiftCardJobCreator.new(order) }

  describe "run" do
    it "queues each gift card job" do
      job1 = double(Spree::IssueGiftCardJob)
      job2 = double(Spree::IssueGiftCardJob)
      jobs = [job1, job2]
      allow(creator).to receive(:jobs).and_return(jobs)

      expect(Delayed::Job).to receive(:enqueue).with(job1, queue: 'gift_card')
      expect(Delayed::Job).to receive(:enqueue).with(job2, queue: 'gift_card')

      creator.run
    end
  end

  describe "jobs" do
    let(:line_item_1) { double(Spree::LineItem, quantity: 1) }
    let(:line_item_2) { double(Spree::LineItem, quantity: 2) }
    let(:line_items) { [line_item_1, line_item_2] }

    before do
      allow(order).to receive(:gift_card_line_items).and_return(line_items)
    end

    it "creates a gift card job for each gift card line item" do
      job1 = double(Spree::IssueGiftCardJob)
      job2 = double(Spree::IssueGiftCardJob)
      job3 = double(Spree::IssueGiftCardJob)

      expect(Spree::IssueGiftCardJob).to receive(:new).
        with(order, line_item_1, 0).
        and_return(job1)
      expect(Spree::IssueGiftCardJob).to receive(:new).
        with(order, line_item_2, 0).
        and_return(job2)
      expect(Spree::IssueGiftCardJob).to receive(:new).
        with(order, line_item_2, 1).
        and_return(job3)

      expect(creator.send(:jobs)).to eq([job1, job2, job3])
    end
  end
end
