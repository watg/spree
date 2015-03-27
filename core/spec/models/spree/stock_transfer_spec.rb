require 'spec_helper'

module Spree
  describe StockTransfer, :type => :model do
    let(:destination_location) { create(:stock_location_with_items) }
    let(:source_location) { create(:stock_location_with_items) }
    let(:stock_item) { source_location.stock_items.order(:id).first }
    let(:variant) { stock_item.variant }
    let(:stock_transfer_items) { [] }

    subject { StockTransfer.create(reference: 'PO123') }

    describe '#reference' do
      subject { super().reference }
      it { is_expected.to eq 'PO123' }
    end

    describe '#to_param' do
      subject { super().to_param }
      it { is_expected.to match /T\d+/ }
    end

    it "validates reference uniqueness" do
      new_stock_transfer = subject.dup
      expect(new_stock_transfer.valid?).to eq false
    end

    it "considers suppliers and creates stock items if they do not exist at destination" do
      location1 = create(:stock_location)
      location2 = create(:stock_location)
      variant = create(:variant)
      supplier = create(:supplier, firstname: "Supplier1")
      stock_item = create(:stock_item, variant: variant, supplier: supplier, stock_location: location1)

      stock_transfer_items << Spree::StockTransfer::TransferItem.new(variant, 5, supplier)

      expect(stock_item.count_on_hand).to eq 10
      subject.transfer(location1, location2, stock_transfer_items)

      new_stock_item = location2.stock_items.find_by(variant: variant, supplier: supplier)
      expect(new_stock_item).to be_present
      expect(new_stock_item.count_on_hand).to eq 5
      expect(new_stock_item.supplier).to eq supplier

      expect(stock_item.reload.count_on_hand).to eq 5
      expect(stock_item.supplier).to eq supplier
    end

    it 'transfers variants between 2 locations' do
      stock_transfer_items << Spree::StockTransfer::TransferItem.new(variant, 5)

      subject.transfer(source_location,
                       destination_location,
                       stock_transfer_items)

      expect(source_location.count_on_hand(variant)).to eq 5
      expect(destination_location.count_on_hand(variant)).to eq 5
      expect(subject.stock_movements.size).to eq(2)

      expect(subject.source_location).to eq source_location
      expect(subject.destination_location).to eq destination_location

      expect(subject.source_movements.first.quantity).to eq -5
      expect(subject.destination_movements.first.quantity).to eq 5
    end

    it 'receive new inventory (from a vendor)' do
      stock_transfer_items << Spree::StockTransfer::TransferItem.new(variant, 5)

      subject.receive(destination_location, stock_transfer_items)

      expect(destination_location.count_on_hand(variant)).to eq 5
      expect(subject.stock_movements.size).to eq(1)

      expect(subject.source_location).to be_nil
      expect(subject.destination_location).to eq destination_location
    end
  end
end
