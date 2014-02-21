require 'spec_helper'

describe Spree::AnalyticJob do
  let(:order) { create(:completed_order_with_totals) }

  subject { Spree::AnalyticJob.new(order: nil, user_id: 'uuid', event: :transaction)}
  it "performs transaction" do
    expect(subject).to receive(:transaction)
    subject.perform
  end

  it "raises an error on unknown event" do
    bad_job = Spree::AnalyticJob.new(order: nil, user_id: 'uuid', event: :bad)
    expect { bad_job.perform }.to raise_error
  end

  describe "#transaction" do
    let!(:payment) { create(:payment, order: order, state: 'completed')}
    it "creates transaction details" do
      actual = subject.send(:ga_transaction_details, order, 'uuid')
      expect(actual).to include(cid: 'uuid',
                                ti: order.number,
                                tr: order.total.to_f,
                                tt: order.tax.to_f,
                                ts: order.shipments.last.cost.to_f)
    end

    it "creates item details" do
      li = order.line_items.first
      actual = subject.send(:ga_item_details, li, 'uuid')
      expect(actual).to include(ti:  li.order.number,
        in:  li.variant.name,
        ip:  li.price.to_f,
        iq:  li.quantity,
        ic:  li.variant.sku,
        iv:  (li.variant.product.product_type.respond_to?(:name) ? li.variant.product.product_type.name : li.variant.product.product_type),
        cu:  li.order.currency)
      
    end

  end
end
