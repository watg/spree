require 'spec_helper'

module Spree
  describe StockReport do

    describe "#header" do
      it "should return the header" do
        expect(subject.header).to be_kind_of Array
      end
    end

    describe "#retrieve_data" do
      subject {
        data = []
        described_class.new.retrieve_data {|d| data << d}
        data.flatten
      }

      it "should run fine without data (this tests the sql)" do
        expect(subject).to eq []
      end

      context 'with data' do
        let(:prices) { [
          build(:price, :currency => 'GBP', :amount => 12),
          build(:price, :currency => 'USD', :amount => 13),
          build(:price, :currency => 'EUR', :amount => 14),
          build(:price, :currency => 'GBP', :amount => 2, :sale => true),
          build(:price, :currency => 'USD', :amount => 3, :sale => true),
          build(:price, :currency => 'EUR', :amount => 4, :sale => true),
          build(:price, :currency => 'GBP', :amount => 5, :is_kit => true),
          build(:price, :currency => 'USD', :amount => 6, :is_kit => true),
          build(:price, :currency => 'EUR', :amount => 7, :is_kit => true),
        ] }

        before do
          @variant = Variant.new(sku: 'SKU1')
          @variant.prices = prices

          @marketing_type = build_stubbed(:marketing_type)
          @product = Product.new(name: 'Product 1', marketing_type: @marketing_type)
          @product.variants << @variant

          @supplier = build(:supplier)
          @stock_location = build_stubbed(:base_stock_location)
          @stock_item = StockItem.new(variant: @variant, supplier: @supplier, stock_location: @stock_location)
          @stock_item.send(:count_on_hand=, 67)
          # stub out the db lookup
          allow_any_instance_of(described_class).to receive(:loop_stock_items).and_yield @stock_item
        end

        context "its size should be the same as the header" do
          its(:size) { should eq described_class.new.header.size }
        end

        [:name, :sku].each do |method|
          it { should include @product.send(method) }
        end

        [:sku, :options_text, :cost_price].each do |method|
          it { should include @variant.send(method) }
        end

        [:name].each do |method|
          it { should include @marketing_type.send(method) }
        end

        [:name].each do |method|
          it { should include @supplier.send(method) }
        end

        [:name].each do |method|
          it { should include @stock_location.send(method) }
        end

        [:count_on_hand].each do |method|
          it { should include @stock_item.send(method) }
        end

        context 'prices' do
          ['USD', 'GBP', 'EUR'].each do |currency|
            it { should include Spree::Price.find_normal_price(prices, currency).price.to_s }
            it { should include Spree::Price.find_part_price(prices, currency).price.to_s }
            it { should include Spree::Price.find_sale_price(prices, currency).price.to_s }
          end
        end

      end

    end
  end
end


