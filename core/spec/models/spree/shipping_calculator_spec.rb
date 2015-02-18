require 'spec_helper'

module Spree
  describe ShippingCalculator, :type => :model do
    let(:variant1) { build(:variant) }
    let(:variant2) { build(:variant) }

    let(:line_item1) { build(:line_item, quantity: 2, variant: variant1, price: 10) }
    let(:line_item2) { build(:line_item, quantity: 1, variant: variant2, price: 20) }

    let(:package) do
      build(:stock_package, line_items: [ line_item1, line_item2])
    end

    subject { ShippingCalculator.new }

    it 'computes with a shipment' do
      shipment = mock_model(Spree::Shipment)
      expect(subject).to receive(:compute_shipment).with(shipment)
      subject.compute(shipment)
    end

    it 'computes with a package' do
      expect(subject).to receive(:compute_package).with(package)
      subject.compute(package)
    end

    it 'compute_shipment must be overridden' do
      expect {
        subject.compute_shipment(shipment)
      }.to raise_error
    end

    it 'compute_package must be overridden' do
      expect {
        subject.compute_package(package)
      }.to raise_error
    end

    it 'checks availability for a package' do
      expect(subject.available?(package)).to be true
    end

    it 'calculates totals for content_items' do
      expect(subject.send(:total, package.contents)).to eq 40.00
    end
  end
end
