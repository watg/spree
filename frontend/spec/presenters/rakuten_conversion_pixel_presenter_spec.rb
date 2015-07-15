require "spec_helper"
describe RakutenConversionPixelPresenter do
  context "an order with kits with diferent options" do
    let(:order) { create(:order, line_items: [line_item_1, line_item_2]) }
    let(:product) { create(:product, product_type: create(:product_type_kit)) }
    let(:variant) { create(:variant, product_id: product.id, cost_price: 2, weight: 0) }
    let(:kit_1) do
      pdt = product
      v = variant
      v
    end

    let(:kit_2) do
      pdt = product
      v = variant
      v
    end

    let(:line_item_1) { create(:line_item, variant: kit_1) }
    let(:line_item_2) { create(:line_item, variant: kit_2, quantity: 4) }

    let(:expected_params) do
      { ord:      order.number,
        skulist:  variant.sku,
        qlist:    "5",
        amtlist:  "2000",
        cur:      "USD",
        img:      1,
        namelist: URI.escape(product.name)
      }
    end

    it "returns the correct format" do
      expect(described_class.new(order).default_rakuten_params).to eq expected_params
    end
  end
end
