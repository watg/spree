require 'spec_helper'

describe Spree::Admin::VariantDecorator do

  context "number_of_shipment_pending" do

    let(:variant) {Spree::Admin::VariantDecorator.decorate(stock_item.variant)}
    let(:stock_location) { create(:stock_location_with_items) }
    let(:stock_item) { stock_location.stock_items.order(:id).first }

    let(:order) do
      order = create(:order)
      order.state = 'complete'
      order.completed_at = Time.now
      order.tap(&:save!)
    end

    let(:shipment) do
      shipment = Spree::Shipment.new
      shipment.stock_location = stock_location
      shipment.shipping_methods << create(:shipping_method)
      shipment.order = order
      # We don't care about this in this test
      shipment.stub(:ensure_correct_adjustment)
      shipment.tap(&:save!)
    end

    let!(:unit) do
      unit = shipment.inventory_units.build
      #unit.state = 'backordered'
      unit.variant_id = stock_item.variant.id
      unit.order_id = order.id
      unit.pending = false
      unit.tap(&:save!)
    end

    it "takes into account pending false" do
      expect(variant.number_of_shipment_pending(stock_item)).to eq 1 
    end

    it "takes into account pending true" do
      unit.pending = true
      unit.save
      expect(variant.number_of_shipment_pending(stock_item)).to eq 0 
    end

    it "is influenced by order states" do
      order.cancel!
      expect(variant.number_of_shipment_pending(stock_item)).to eq 0 
      order.resume!
      expect(variant.number_of_shipment_pending(stock_item)).to eq 1
    end

    context "supplier" do
      let(:supplier) { create(:supplier) }

      before do
        unit.supplier = supplier
        unit.save
      end

      it "take no supplier" do
        stock_item.supplier = nil
        expect(variant.number_of_shipment_pending(stock_item)).to eq 0
      end

      it "takes into account a supplier" do
        stock_item.supplier = supplier
        expect(variant.number_of_shipment_pending(stock_item)).to eq 1
      end

    end

    context "stock_location" do
      let(:another_stock_location) { create(:stock_location) }

      before do
        stock_item.stock_location = another_stock_location
      end

      it "takes  account a stock_locations" do
        expect(variant.number_of_shipment_pending(stock_item)).to eq 0
      end

    end

  end

end
