require 'spec_helper'

module Spree
  describe StockTransfer do
    let(:destination_location) { create(:stock_location_with_items) }
    let(:source_location) { create(:stock_location_with_items) }
    let(:stock_item) { source_location.stock_items.order(:id).first }
    let(:variant) { stock_item.variant }
    let(:stock_transfer_items) { [] }

    subject { StockTransfer.create(reference: 'PO123') }

    its(:reference) { should eq 'PO123' }
    its(:to_param) { should match /T\d+/ }

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

      source_location.count_on_hand(variant).should eq 5
      destination_location.count_on_hand(variant).should eq 5
      subject.should have(2).stock_movements

      subject.source_location.should eq source_location
      subject.destination_location.should eq destination_location

      subject.source_movements.first.quantity.should eq -5
      subject.destination_movements.first.quantity.should eq 5
    end

    it 'receive new inventory (from a vendor)' do
      stock_transfer_items << Spree::StockTransfer::TransferItem.new(variant, 5)

      subject.receive(destination_location, stock_transfer_items)

      destination_location.count_on_hand(variant).should eq 5
      subject.should have(1).stock_movements

      subject.source_location.should be_nil
      subject.destination_location.should eq destination_location
    end
  end
end
