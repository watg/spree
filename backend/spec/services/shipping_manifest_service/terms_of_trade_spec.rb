require 'spec_helper'

describe Spree::ShippingManifestService::TermsOfTrade do

  subject { Spree::ShippingManifestService::TermsOfTrade.run(order: order) }

  let(:order) { create(:order, total: 110, ship_total: 10, currency: 'USD'  ) }

  let(:usa) { create(:country)}

  before { order.stub_chain(:ship_address, :country).and_return(usa) }

  context "in the usa" do
    its(:result) { should eq('DDP') }
  end

  context "not in the usa" do
    let(:uk) { create(:country_uk)}

    before { order.stub_chain(:ship_address, :country).and_return(uk) }

    its(:result) { should eq('DDU') }
  end

end
