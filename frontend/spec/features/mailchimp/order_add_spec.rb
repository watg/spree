require "feature_helper"

describe "Adding an order", inaccessible: true do

  let(:interface) { Spree::Chimpy::Interface::Orders.new }
  let(:api)       { double('api', ecomm: double) }
  let(:order)     { FactoryGirl.create(:completed_order_with_totals, :with_marketing_type) }
  let(:true_response) { {"complete" => true } }

  before do
    allow(Spree::Chimpy).to receive(:api).and_return(api)
    # we need to stub :notify_mail_chimp otherwise sync will be called on the order on update!
    allow(order).to receive(:notify_mail_chimp).and_return(true_response)
  end

  it "adds an order" do
    Spree::Chimpy::Config.store_id = "super-store"

    expect(api.ecomm).to receive(:order_add) { |h| expect(h[:id]).to eq(order.number) }.and_return(true_response)
    expect(interface.add(order)).to be true
  end

  it "removes an order" do
    Spree::Chimpy::Config.store_id = "super-store"
    expect(api.ecomm).to receive(:order_del).with('super-store', order.number).and_return(true_response)

    expect(interface.remove(order)).to be true
  end

end
