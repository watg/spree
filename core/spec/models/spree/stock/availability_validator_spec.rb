require 'spec_helper'

module Spree
  module Stock
    describe AvailabilityValidator do

#      let!(:line_item) { double(quantity: 5, target_shipment: nil, variant_id: 1, variant: double.as_null_object, errors: double('errors')) }
      let!(:line_item) { create(:line_item) }

      subject { described_class.new(nil) }

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
    end
  end
end
