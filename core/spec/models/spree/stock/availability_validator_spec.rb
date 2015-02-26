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


      describe "validate" do

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

        context "when variant is deleted" do

          before do
            variant.update_column(:deleted_at, Time.now)
          end

          it 'should not raise an error' do
            allow_any_instance_of(Stock::Quantifier).to receive_messages(can_supply?: true)

            expect(line_item).not_to receive(:errors)
            expect do
              expect(subject.validate(line_item)).to eq true
            end.to_not raise_error
          end

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

        context "The line item exists already and the quantity changes" do
          let!(:line_item) { create(:line_item, quantity: 2) }
          let(:variant) { line_item.variant }
          let(:order) {line_item.order}

          before do
            order.reload
          end

          it "validates the new updated object, and not the old one with a quantity of 2" do
            expect(Stock::Quantifier).to receive(:new).with(variant).and_return quantifier
            expect(quantifier).to receive(:can_supply?).with(3).once.and_return true
            line_item.quantity = 3
            expect(subject.validate(line_item)).to eq true
          end

        end

      end

      describe "invalid_line_items" do

        context "single line item" do

          before  do
            order.save
          end

          it 'should return no line_items if stock exists' do
            allow_any_instance_of(Stock::Quantifier).to receive_messages(can_supply?: true)
            expect(subject.invalid_line_items(order)).to eq []
          end

          it 'should return line_items if stock doe not exist' do
            allow_any_instance_of(Stock::Quantifier).to receive_messages(can_supply?: false)
            expect(subject.invalid_line_items(order)).to eq [line_item]
          end


          context "deleted variant" do

            before do
              variant.update_column(:deleted_at, Time.now)
            end

            it 'should return no line_items if stock exists' do
              allow_any_instance_of(Stock::Quantifier).to receive_messages(can_supply?: false)
              expect(subject.invalid_line_items(order)).to eq [line_item]
            end

          end

        end

        context "multiple line items" do
          before  do
            order.line_items << extra_line_item
            order.save
          end

          it 'should return no line_items if stock exists' do
            expect(Stock::Quantifier).to receive(:new).with(variant).and_return quantifier
            expect(quantifier).to receive(:can_supply?).with(2).and_return true

            expect(Stock::Quantifier).to receive(:new).with(extra_variant).and_return quantifier
            expect(quantifier).to receive(:can_supply?).with(6).and_return true

            expect(subject.invalid_line_items(order)).to eq []
          end

          it 'should return line_items if stock does not exist' do
            expect(Stock::Quantifier).to receive(:new).with(variant).and_return quantifier
            expect(quantifier).to receive(:can_supply?).with(2).and_return true

            expect(Stock::Quantifier).to receive(:new).with(extra_variant).and_return quantifier
            expect(quantifier).to receive(:can_supply?).with(6).and_return false

            expect(subject.invalid_line_items(order)).to eq [extra_line_item]
          end
        end

        context "multiple line items with same variant" do
          let(:extra_line_item_2) { Spree::LineItem.new(variant: variant, quantity: 1) }

          before  do
            order.line_items << extra_line_item_2
            order.save
          end

          it 'sums the qauntity of both line_items and validates the value' do
            expect(Stock::Quantifier).to receive(:new).with(variant).and_return quantifier
            expect(quantifier).to receive(:can_supply?).with(3)
            expect(subject.invalid_line_items(order))
          end

        end

        context "when inventory units exist" do
          before do
            order.save
          end

          it 'should consider non-pending inventory units sufficient' do
            Spree::InventoryUnit.create(variant_id: variant.id, order: order, pending: false)

            expect(Stock::Quantifier).to receive(:new).with(variant).and_return quantifier
            expect(quantifier).to receive(:can_supply?).with(1)

            expect(subject.invalid_line_items(order))
          end

          it 'should consider pending inventory units not sufficient' do
            Spree::InventoryUnit.create(variant_id: variant.id, order: order, pending: true)

            expect(Stock::Quantifier).to receive(:new).with(variant).and_return quantifier
            expect(quantifier).to receive(:can_supply?).with(2)

            expect(subject.invalid_line_items(order))
          end

        end

        context "The line item exists already and the quantity changes" do
          let!(:line_item) { create(:line_item, quantity: 2) }
          let(:variant) { line_item.variant }
          let(:order) {line_item.order}

          before do
            order.reload
          end

          it "validates the new updated object, and not the old one with a quantity of 2" do
            expect(Stock::Quantifier).to receive(:new).with(variant).and_return quantifier
            expect(quantifier).to receive(:can_supply?).with(3).once.and_return true
            line_item.update_column(:quantity, 3)
            expect(subject.invalid_line_items(order)).to be_empty
          end
        end

      end

    end
  end
end
