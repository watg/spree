require 'spec_helper'

describe Spree::ShippingManifestService::ShippingCosts do

  subject { Spree::ShippingManifestService::ShippingCosts.run(order: order) }

  let(:order) { create(:order, total: 110, ship_total: 10, currency: 'USD'  ) }

  describe ".shipping_cost" do

    before do
      order.stub(shipping_discount: 5)
    end

    its(:result) { should eq(BigDecimal.new(5)) }
  end
end
