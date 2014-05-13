require 'spec_helper'

module Spree
  module Stock
    describe AvailabilityValidator do

      subject { described_class.new(nil) }


      let!(:line_item) { create(:line_item) }

      it 'should be valid when supply is sufficient' do
        allow(Stock::Quantifier).to receive(:can_supply_order?).and_return({errors: []})
        line_item.errors.should_not_receive(:[]).with(:quantity)
        subject.validate(line_item)
      end

      it 'should be invalid when supply is insufficent' do
        allow(Stock::Quantifier).to receive(:can_supply_order?).and_return({
          errors: [{line_item_id: line_item.id}]})
        line_item.errors.should_receive(:[]).with(:quantity).and_return []
        subject.validate(line_item)
      end

      it 'should return true if quantity is decremented' do
        Spree::StockItem.any_instance.stub(backorderable: false)
        line_item.update_column(:quantity, 2)
        line_item.reload
        line_item.quantity -= 1
        line_item.errors.should_not_receive(:[]).with(:quantity)
        subject.validate(line_item)
      end

    end
  end
end
