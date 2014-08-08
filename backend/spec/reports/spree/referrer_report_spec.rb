require 'spec_helper'

describe Spree::ReferrerReport do
  subject { Spree::ReferrerReport.new }

  let(:order) {
    create(:order,
      number: "R123123",
      currency: "USD",
      completed_at: DateTime.parse("2014-08-12 21:15:00"),
      promo_total: 22.00,
      item_total: 55.00,
      total: 59.00
    )
  }
  let(:referrer) {  Spree::Raf::Referrer.create!(user: mock_model(Spree.user_class, email: "referrer@wool.gang"), currency: "USD") }
  let(:gift_card) { create(:gift_card, state: 'redeemed', beneficiary_order: order, beneficiary_email: order.email) }
  let(:referee) { Spree::Raf::Referee.create!(email: "referee@wool") }
  let(:reward) {
    Spree::Raf::Reward.create!(
      referrer: referrer,
      referee: referee,
      state: :approved,
      redeemed_at: DateTime.parse("2014-09-10 20:10:00"),
      created_at: DateTime.parse("2014-08-09 20:10:00"),
      rewardable: gift_card,
      amount: 5
    )
  }


  it "retuns a data row" do
    row = subject.send(:data_row, reward)
    to_usd_rate = Helpers::CurrencyConversion::TO_GBP_RATES["USD"]

    expect(row.length).to eq subject.header.length
    expect(row).to match_array([
      "referrer@wool.gang",
      "referee@wool",
      "USD",
      Date.parse("2014-08-09").to_date,
      5,
      :approved,
      Date.parse("2014-09-10").to_date,
      "R123123",
      Date.parse("2014-08-12").to_date,
      "USD",
      22.00,
      22.00 * to_usd_rate,
      55.00,
      55.00 * to_usd_rate,
      59.00,
      59.00 * to_usd_rate
    ])
  end

  it "returns headers" do
    expect(subject.header).to match_array(
      %w(
        referrer
        referee
        referrer_currency
        referee_order_date
        reward_amount
        state
        reward_redeemed_date
        order_number
        order_date
        order_currency
        order_promo_total
        order_promo_total_gbp
        order_item_total
        order_item_total_gbp
        order_total
        order_total_gbp
      )
    )
  end

end
