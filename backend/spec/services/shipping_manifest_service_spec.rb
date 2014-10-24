require 'spec_helper'

describe Spree::ShippingManifestService do

  subject { Spree::ShippingManifestService.run(order: order) }

  let(:order) { create(:order, total: 110, ship_total: 10, currency: 'USD'  ) }
  let(:usa) { create(:country)}
  let(:variant) { create(:base_variant) }
  let(:supplier) { create(:supplier) }
  let(:line_item_1) { create(:line_item, order: order, variant: variant) }
  let!(:inventory_unit_1) { create(:base_inventory_unit, line_item: line_item_1, order: order, variant: variant, supplier: supplier) }

  before do
    order.stub(shipping_discount: 5)
    order.stub_chain(:ship_address, :country).and_return(usa)
  end

  it "returns all the params" do
    result = subject.result
    expect(result[:order_total]).to eq(BigDecimal.new(110))
    expect(result[:terms_of_trade_code]).to eq('DDP')
    expect(result[:shipping_costs]).to eq(BigDecimal.new(5))
    expect(result[:unique_products].count).to eq 1
    expect(result[:unique_products].first[:mid_code]).to eq supplier.mid_code
    expect(result[:unique_products].first[:quantity]).to eq 1
    expect(result[:unique_products].first[:total_price].to_f).to eq 105.00
    expect(result[:unique_products].first[:product]).to eq variant.product
    expect(result[:unique_products].first[:group]).to eq variant.product.product_group
  end

  context "no supplier" do
    let!(:inventory_unit_1) { create(:base_inventory_unit, line_item: line_item_1, order: order, variant: variant) }

    it "retuns errors" do
      expect(subject.valid?).to be_false
      expect(subject.errors.full_messages.to_sentence).to eq "Missing supplier for product: #{variant.product.name} (ID: #{variant.product.id}) for order ##{order.number}"
    end

  end

end
