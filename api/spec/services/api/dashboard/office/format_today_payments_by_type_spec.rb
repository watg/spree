require "spec_helper"
describe Api::Dashboard::Office::FormatTodayPaymentsByType, type: :interaction do
  let!(:order1) { create(:order, completed_at: Time.zone.now) }
  let!(:order2) { create(:order, completed_at: Time.zone.now) }
  let!(:order3) { create(:order, completed_at: Time.zone.now) }

  let(:paypal) { create :paypal_payment_method }
  let(:adyen) { create :adyen_payment_method }

  let!(:payment_order1_1) do
    create(:payment, order: order1, payment_method: paypal)
  end

  let!(:payment_order1_2) do
    create(:payment, order: order1, payment_method: adyen)
  end

  let!(:payment_order2_1) do
    create(:payment, order: order2, payment_method: adyen)
  end

  let!(:payment_order3_1) do
    create(:payment, order: order3, payment_method: paypal)
  end
  subject { described_class.new }
  describe "execute" do
    it "returns todays orders by currency" do
      allow_any_instance_of(Api::Dashboard::Office::FindTodayValidOrders)
        .to receive(:run).and_return(Spree::Order.all)
      expect(subject.run)
        .to match_array([[paypal.name, 1], [adyen.name, 1], ["#{adyen.name} / #{paypal.name}", 1]])
    end
  end
end
