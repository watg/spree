require 'spec_helper'

module Spree
  module Stock
    describe AvailabilityValidator do
      let(:variant) { create(:variant) }
      let(:extra_variant) { create(:variant) }

      let(:order) { Spree::Order.new(id: 21) }
      let(:line_item) { Spree::LineItem.new(variant: variant, quantity: 2) }
      let(:extra_line_item) { Spree::LineItem.new(variant: extra_variant, quantity: 6) }

      let(:quantifier) { double }

      before do
        order.line_items << line_item
      end

      describe "validation of line item" do

        it 'should be valid when supply is sufficient' do
          allow_any_instance_of(Stock::Quantifier).to receive_messages(can_supply?: true)

          expect(line_item).not_to receive(:errors)
          expect(subject.validate(line_item)).to eq true
        end

        it 'should be invalid when supply is insufficent' do
          allow_any_instance_of(Stock::Quantifier).to receive_messages(can_supply?: false)

          expect(line_item.errors).to receive(:[]).with(:quantity).and_return []
          expect(subject.validate(line_item)).to eq false
        end

        it "does not validate other line items" do
          order.line_items << extra_line_item
          expect(Stock::Quantifier).not_to receive(:new).with(extra_variant)

          expect(Stock::Quantifier).to receive(:new).with(variant).and_return quantifier
          expect(quantifier).to receive(:can_supply?).with(2).and_return true

          expect(line_item).not_to receive(:errors)
          expect(subject.validate(line_item)).to eq true
        end

        context "when variant is required by other line items" do
          before do
            order.line_items << Spree::LineItem.new(variant: variant, quantity: 10)
            line_item.quantity = 0
          end

          it "should not add errors if the line item quantity required is eq to 0" do
            allow_any_instance_of(Stock::Quantifier).to receive_messages(can_supply?: false)

            expect(line_item).not_to receive(:errors)
            expect(subject.validate(line_item)).to eq true
          end
        end

        context "when inventory units exist" do
          before do
            allow_any_instance_of(Stock::Quantifier).to receive_messages(can_supply?: false)
            Spree::InventoryUnit.create(variant_id: variant.id, order: order, pending: false)
          end

          it 'should consider pending inventory units not sufficient' do
            Spree::InventoryUnit.create(variant_id: variant.id, order: order, pending: true)

            expect(line_item.errors).to receive(:[]).with(:quantity).and_return []
            expect(subject.validate(line_item)).to eq false
          end

          it 'should consider non-pending inventory units sufficient' do
            Spree::InventoryUnit.create(variant_id: variant.id, order: order, pending: false)

            expect(line_item).not_to receive(:errors)
            expect(subject.validate(line_item)).to eq true
          end
        end
      end

      it 'should consider existing inventory_units sufficient' do
        allow_any_instance_of(Stock::Quantifier).to receive_messages(can_supply?: false)
        expect(line_item).not_to receive(:errors)
        allow(line_item).to receive_messages(inventory_units: [double] * 5)
        subject.validate(line_item)
      end
    end
  end
end
