require "spec_helper"
describe Api::Dashboard::Office::FindTodayValidOrders, type: :interaction do
  let!(:valid_paypal_order) do
    create(:order,
           completed_at: Time.zone.now,
           internal: false,
           email: "valid@go.com",
           state: "complete")
  end

  let!(:valid_credit_order)do
    create(:order,
           completed_at: Time.zone.now,
           internal: false,
           email: "valid@go.com",
           state: "complete")
  end

  let!(:internal_order)do
    create(:order,
           completed_at: Time.zone.now,
           email: "request@woolandthegang.com",
           internal: true,
           state: "complete")
  end

  let!(:canceled_order) do
    create(:order,
           completed_at: Time.zone.now,
           internal: false,
           email: "valid@go.com",
           state: "canceled")
  end

  let!(:test_order) do
    create(:order, completed_at: Time.zone.now, state: "complete")
  end

  let!(:paypal_payment_method) do
    create(:paypal_payment_method)
  end

  let!(:test_payment_method) do
    create(:test_payment_method)
  end

  let!(:credit_card_payment_method) do
    create(:credit_card_payment_method)
  end

  let!(:internal_order_payment) do
    create(:payment, order: internal_order, payment_method: paypal_payment_method)
  end

  let!(:test_order_payment) do
    create(:payment, order: test_order, payment_method: test_payment_method)
  end

  let!(:valid_paypal_order_payment) do
    create(:payment, order: valid_paypal_order, payment_method: paypal_payment_method)
  end

  let!(:valid_credit_order_payment) do
    create(:payment, order: valid_credit_order, payment_method: credit_card_payment_method)
  end

  subject { described_class.new }

  describe "execute" do
    it "it should return valid orders" do
      expect(subject.run).to include(valid_credit_order)
      expect(subject.run).to include(valid_paypal_order)
    end
    it "it should not invalid orders" do
      expect(subject.run).not_to include(internal_order)
      expect(subject.run).not_to include(test_order)
    end
  end
end
