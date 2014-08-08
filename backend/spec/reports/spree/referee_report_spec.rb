require 'spec_helper'

describe Spree::RefereeReport do
  subject { Spree::RefereeReport.new }

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
  let(:referrer) {  Spree::Raf::Referrer.create!(user: mock_model(Spree.user_class, email: "referrer@wool.gang"), currency: 'USD') }
  let(:promotion) {
    promotion = Spree::Promotion.new(
                             name: "Refer a Friend",
                             usage_limit: 1,
                             match_policy: "all",
                             dynamic: true
                            )

    calculator = Spree::Calculator::FlatPercentItemTotal.new()
    calculator.set_preference(:flat_percent, 15)
    action = Spree::Promotion::Actions::CreateAdjustment.new()
    action.calculator = calculator

    promotion.actions << action
    promotion.save!
    promotion
  }

  let(:referee) {
    Spree::Raf::Referee.create!(
      email: "referee@wool",
      referrer: referrer,
      promotion: promotion,
      source: "twitter"
    )
  }

  let(:reward) {
    Spree::Raf::Reward.create!(
      referee: referee,
      order: order
    )
  }


  it "retuns a data row" do
    reward.reload
    row = subject.send(:data_row, referee)

    expect(row.length).to eq subject.header.length
    expect(row).to match_array([
      "referee@wool",
      "referrer@wool.gang",
      referee.created_at.to_date,
      "twitter",
      15,
      0,
      "R123123",
      Date.parse("2014-08-12 21:15:00").to_date,
      "USD",
      22.00,
      55.00,
      59.00
    ])
  end

  it "returns headers" do
    expect(subject.header).to match_array(
      %w(
        referee
        referrer
        referee_sign_up_date
        source
        percentage_discount
        applied_to_order
        order_number
        order_date
        order_currency
        order_promo_total
        order_item_total
        order_total
      )
    )
  end

end
