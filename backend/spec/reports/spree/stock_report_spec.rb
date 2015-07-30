require "spec_helper"

module Spree
  describe StockReport do
    describe "#header" do
      it "returns the header" do
        expect(subject.header).to be_kind_of Array
      end
    end

    describe "#retrieve_data" do
      subject do
        data = []
        described_class.new.retrieve_data { |d| data << d }
        data.flatten
      end

      it "runs fine without data (this tests the sql)" do
        expect(subject).to eq []
      end

      context "with data" do
        let(:prices) do
          [
            create(:price, currency: "GBP", amount: 12),
            create(:price, currency: "USD", amount: 13),
            create(:price, currency: "EUR", amount: 14),
            create(:price, currency: "GBP", amount: 2, sale: true),
            create(:price, currency: "USD", amount: 3, sale: true),
            create(:price, currency: "EUR", amount: 4, sale: true),
            create(:price, currency: "GBP", amount: 5, is_kit: true),
            create(:price, currency: "USD", amount: 6, is_kit: true),
            create(:price, currency: "EUR", amount: 7, is_kit: true)
          ]
        end

        before do
          @variant = Variant.new(sku: "SKU1")
          @variant.prices = prices

          @marketing_type = build_stubbed(:marketing_type)
          @product = Product.new(name: "Product 1", marketing_type: @marketing_type)
          @product.variants << @variant

          @supplier = build(:supplier)
          @stock_location = build_stubbed(:base_stock_location)
          @stock_item = StockItem.new(variant: @variant, supplier: @supplier, stock_location: @stock_location)
          @stock_item.send(:count_on_hand=, 67)
          # stub out the db lookup
          allow_any_instance_of(described_class).to receive(:loop_stock_items).and_yield @stock_item
        end

        context "its size should be the same as the header" do
          describe "#size" do
            it { expect(subject.size).to eq described_class.new.header.size }
          end
        end

        [:name, :sku].each do |method|
          it { is_expected.to include @product.send(method) }
        end

        [:sku, :options_text, :cost_price].each do |method|
          it { is_expected.to include @variant.send(method) }
        end

        [:name].each do |method|
          it { is_expected.to include @marketing_type.send(method) }
        end

        [:name].each do |method|
          it { is_expected.to include @supplier.send(method) }
        end

        [:name].each do |method|
          it { is_expected.to include @stock_location.send(method) }
        end

        [:count_on_hand].each do |method|
          it { is_expected.to include @stock_item.send(method) }
        end

        context "prices" do
          %w(USD GBP EUR).each do |currency|
            it "have normal_price" do
              price = Spree::Price.find_part_price(prices, currency).price.to_s
              expect(subject).to include(price)
            end

            it "have part_price" do
              price = Spree::Price.find_part_price(prices, currency).price.to_s
              expect(subject).to include(price)
            end

            it "have sale_price" do
              price = Spree::Price.find_part_price(prices, currency).price.to_s
              expect(subject).to include(price)
            end
          end
        end
      end
    end
  end
end
