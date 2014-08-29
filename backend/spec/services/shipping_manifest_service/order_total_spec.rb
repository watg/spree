require 'spec_helper'

describe Spree::ShippingManifestService::OrderTotal do

  subject { Spree::ShippingManifestService::OrderTotal.run(order: order) }

  let(:order) { create(:order, total: 110, ship_total: 10, currency: 'USD'  ) }

  its("result") { should eq(BigDecimal.new(110)) }

  context "with gift card adjustment" do
    let!(:adjustment) { create(:gift_card_adjustment, adjustable: order, amount: 10) }

    it "will add the gift card adjustment to the total" do
      expect(subject.result).to eq(BigDecimal.new(120))
    end
  end

  context "with digital line items" do

    let(:digital_product) { create(:product, product_type: create(:product_type_gift_card)) }
    let!(:line_item) { create(:line_item, variant: digital_product.master, order: order, price: 12.00, quantity: 2) }

    it "it will subtract them from the total" do
      expect(subject.result).to eq(BigDecimal.new(86))
    end
  end

end
