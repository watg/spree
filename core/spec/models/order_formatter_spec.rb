require 'spec_helper'

describe Spree::OrderFormatter do
  let(:order) { create(:order) }
  subject { Spree::OrderFormatter.new(order) }

  describe 'Initialization' do
    it 'Sets up the @order variable' do
      expect(subject.instance_variable_get(:@order)).to eql(order)
    end
  end

  describe 'Data Formatting' do
    subject { Spree::OrderFormatter.new(order).order_data }

    it { expect(subject).to have_key(:order_number) }
    it { expect(subject).to have_key(:email) }
    it { expect(subject).to have_key(:items) }
    it { expect(subject).to have_key(:items_total) }
    it { expect(subject).to have_key(:shipment_total) }
    it { expect(subject).to have_key(:adjustments) }
    it { expect(subject).to have_key(:promotions) }
    it { expect(subject).to have_key(:adjustments_total) }
    it { expect(subject).to have_key(:delivery_time) }
    it { expect(subject).to have_key(:currency) }
    it { expect(subject).to have_key(:payment_total) }
  end

  describe "Data entries" do
    subject { Spree::OrderFormatter.new(order) }
    let!(:foo) { Spree::Adjustment.new(order: order, source_type: "Spree::PromotionAction", eligible: true, label: 'foo', amount: 2) }

    before do
      Shipping::Coster.any_instance.stub(final_price: 20, adjustment_total: -5)
      allow(order).to receive(:all_adjustments).and_return([foo])
    end

    describe "#shipment_total" do
      it "does something" do
        data = subject.order_data
        expect(data[:shipment_total]).to eq("$20.00")
        expect(data[:adjustments_total]).to eq("-$5.00")
        expect(data[:promotions]).to include(">$2.00<")
      end
    end
  end
end


# def shipment_total
#   format_money shipment_coster.final_price
# end

# def adjustments_total
#   format_money @order.adjustment_total + shipment_coster.adjustment_total
# end

# def promotions
#   adjustments = adjustments_selector.promotion.eligible.without_shipping_rate.group_by(&:label)
#   # promotions = @order.all_adjustments.promotion.eligible.group_by(&:label)
#   adjustments_template(adjustments)
# end

# def shipment_coster
#   ::Shipping::Coster.new(@order.shipments)
# end

# def adjustments_selector
#   ::Adjustments::Selector.new(@order.all_adjustments)
# end