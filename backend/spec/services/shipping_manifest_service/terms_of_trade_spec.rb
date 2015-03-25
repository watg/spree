require 'spec_helper'

describe Spree::ShippingManifestService::TermsOfTrade do

  subject(:service) { Spree::ShippingManifestService::TermsOfTrade.run(order: order) }

  let(:order) { create(:order, total: 110, ship_total: 10, currency: 'USD'  ) }


  it "returns DDP for party orders for Canada" do
    canada = create(:country_canada)
    order.order_type = create(:party_order_type)
    allow(order).to receive_message_chain(:ship_address, :country).and_return(canada)
    expect(service.result).to eq('DDP')
  end

  it "returns DDU for non-party orders for Canada eh" do
    canada = create(:country_canada)
    allow(order).to receive_message_chain(:ship_address, :country).and_return(canada)
    expect(service.result).to eq('DDU')
  end

  it "returns DDP for the USA" do
    usa = create(:country)
    allow(order).to receive_message_chain(:ship_address, :country).and_return(usa)
    expect(service.result).to eq('DDP')
  end

  it "returns DDU for countries outside USA" do
    uk = create(:country_uk)
    allow(order).to receive_message_chain(:ship_address, :country).and_return(uk)
    expect(service.result).to eq('DDU')
  end

end
