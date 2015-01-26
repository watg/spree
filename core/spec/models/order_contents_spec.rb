require 'spec_helper'

describe Spree::OrderContents do
  let(:order)   { create(:order) }
  let(:variant) { create(:variant) }
  let(:subject) { Spree::OrderContents.new(order) }
  let(:currency){ 'USD' }

  let!(:price) { build(:price, is_kit: true, amount: 5) }

  before do
    variant.price_normal_in('USD').amount = 19.99
    allow_any_instance_of(Spree::Variant).to receive_messages(:price_part_in => price)
  end

  context "#add" do
    it "should set the correct attributes to the line item" do
      options = { target_id: 2 }
      line_item = subject.add(variant, 1, options)

      expect(line_item.variant).to eq(variant)
      expect(line_item.target_id).to eq(2)
      expect(line_item.currency).to eq('USD')
    end

    it "should create different line items for different targets" do
      line_item1 = subject.add(variant, 1, { target_id: 1 })
      line_item2 = subject.add(variant, 1, { target_id: 2 })

      expect(line_item1.variant).to eq(variant)
      expect(line_item1.target_id).to eq(1)

      expect(line_item2.variant).to eq(variant)
      expect(line_item2.target_id).to eq(2)
    end

    context 'suite params' do
      let(:options) { { suite_id: 21, suite_tab_id: 22 } }

      it "should add suite params to the line_item" do
        line_item = subject.add(variant, 1, options)
        expect(line_item.suite_id).to eq(21)
        expect(line_item.suite_tab_id).to eq(22)
      end
    end

    context 'given parts' do
      let(:variant_option1) { create(:variant) }
      let(:variant_option2) { create(:variant) }

      let(:line_item_part_params) {[
        Spree::LineItemPart.new(
                       variant_id: variant_option1.id,
                       quantity:   3,
                       optional:   true,
                       price:      5,
                       currency:   'GBP'
                      )
      ]}

      let(:line_item_part_params2) {[
        Spree::LineItemPart.new(
                       variant_id: variant_option2.id,
                       quantity:   2,
                       optional:   true,
                       price:      5,
                       currency:   'GBP'
                      )
      ]}

      let(:line_item_part_params3) {[
        Spree::LineItemPart.new(
                       variant_id: variant_option2.id,
                       quantity:   5,
                       optional:   true,
                       price:      5,
                       currency:   'GBP'
                      )

      ]}

      let(:line_item_part_params4) {[
        Spree::LineItemPart.new(
                       variant_id: variant_option1.id,
                       quantity:   7,
                       optional:   true,
                       price:      5,
                       currency:   'GBP'
                      ),
        Spree::LineItemPart.new(
                       variant_id: variant_option2.id,
                       quantity:   2,
                       optional:   true,
                       price:      5,
                       currency:   'GBP'
                      )
      ]}


      it 'should add one line item with one option' do
        options = { parts: line_item_part_params }
        line_item = subject.add(variant,1, options)

        expect(line_item.quantity).to eq(1)
        expect(order.line_items.size).to eq(1)
        expect(line_item.line_item_parts.size).to eq(1)
        line_item.line_item_parts.first.variant == variant_option1
        line_item.line_item_parts.first.quantity == 3
      end

      it 'should only have one line item with same option' do
        options = { parts: line_item_part_params }
        line_item = subject.add(variant, 1, options)
        line_item2 = subject.add(variant, 1, options)
        line_item.reload

        expect(line_item.quantity).to eq(2)
        expect(line_item).to eq(line_item2)
        expect(order.line_items.size).to eq(1)
        expect(line_item.line_item_parts.size).to eq(1)
      end

      it 'should have multiple line items with different options' do
        options1 = { parts: line_item_part_params }
        options2 = { parts: line_item_part_params2 }
        line_item = subject.add(variant, 1, options1)
        line_item2 = subject.add(variant, 1, options2)

        expect(line_item.quantity).to eq(1)
        expect(line_item2.quantity).to eq(1)
        expect(order.line_items.size).to eq(2)
        expect(line_item.line_item_parts.size).to eq(1)
        expect(line_item2.line_item_parts.size).to eq(1)
      end

      it 'should have multiple line items with different options' do
        options1 = { parts: line_item_part_params2 }
        options2 = { parts: line_item_part_params3 }
        line_item = subject.add(variant, 1, options1)
        line_item2 = subject.add(variant, 1, options2)

        expect(line_item.quantity).to eq(1)
        expect(line_item2.quantity).to eq(1)
        expect(order.line_items.size).to eq(2)
        expect(line_item.line_item_parts.size).to eq(1)
        expect(line_item2.line_item_parts.size).to eq(1)
      end

      it 'should only have one line item with same option when multiple options' do
        options1 = { parts: line_item_part_params4 }
        options2 = { parts: line_item_part_params4 }
        line_item = subject.add(variant, 1, options1)
        line_item2 = subject.add(variant, 1, options2)

        line_item.reload
        expect(line_item.quantity).to eq(2)
        expect(line_item).to eq(line_item2)
        expect(order.line_items.size).to eq(1)
        expect(line_item.line_item_parts.size).to eq(2)
      end

      it "should update order totals" do
        options1 = { parts: line_item_part_params }
        options2 = { parts: line_item_part_params2 }
        subject.add(variant, 1, options1)
        subject.add(variant, 1, options1)
        subject.add(variant, 1, options2)

        # 99.97 = 3 * 19.99 + 5*3 + 5*3 + 5*2
        expect(order.item_total.to_f).to eq(99.97)
        expect(order.total.to_f).to eq(99.97)
      end
    end

    context 'given a personalisation' do
      let(:monogram) { create(:personalisation_monogram) }
      let(:personalisation_params) {[ Spree::LineItemPersonalisation.new(
        personalisation_id: monogram.id,
        amount: 1,
        data: { 'colour' => monogram.colours.first.id, 'initials' => 'DD'},
      )]}

      let(:personalisation_params2) {[Spree::LineItemPersonalisation.new(
        personalisation_id: monogram.id,
        amount: 1,
        data: { 'colour' => monogram.colours.first.id, 'initials' => 'XX'},
      )]}

      let(:personalisation_params3) {[
        Spree::LineItemPersonalisation.new(
          personalisation_id: monogram.id,
          amount: 1,
          data: { 'colour' => monogram.colours.first.id, 'initials' => 'XX'},
        ),
        Spree::LineItemPersonalisation.new(
          personalisation_id: monogram.id,
          amount: 2,
          data: { 'colour' => monogram.colours.first.id, 'initials' => 'WW'},
        ),
      ]}

      it 'should add one line item with one personalisation' do
        options = { personalisations: personalisation_params }
        line_item = subject.add(variant, 1, options)

        expect(line_item.quantity).to eq(1)
        expect(order.line_items.size).to eq(1)
        expect(line_item.line_item_personalisations.size).to eq(1)
        line_item.line_item_personalisations.first.name == 'monogram'
        line_item.line_item_personalisations.first.amount == BigDecimal.new('1')
      end

      it 'should only have one line item with same personalisations' do
        options = { personalisations: personalisation_params }
        line_item = subject.add(variant, 1, options)
        line_item2 = subject.add(variant, 1, options)

        line_item.reload
        expect(line_item.quantity).to eq(2)
        expect(line_item).to eq(line_item2)
        expect(order.line_items.size).to eq(1)
        expect(line_item.line_item_personalisations.size).to eq(1)
      end

      it 'should only have multiple line item with different personalisations' do
        options1 = { personalisations: personalisation_params }
        options2 = { personalisations: personalisation_params2 }
        line_item = subject.add(variant, 1, options1)
        line_item2 = subject.add(variant, 1, options2)

        expect(line_item.quantity).to eq(1)
        expect(line_item2.quantity).to eq(1)
        expect(order.line_items.size).to eq(2)
        expect(line_item.line_item_personalisations.size).to eq(1)
        expect(line_item2.line_item_personalisations.size).to eq(1)
      end

      it 'should only have one line item with multiple personalisations in same line item' do
        options = { personalisations: personalisation_params3 }
        line_item = subject.add(variant, 1, options)
        line_item2 = subject.add(variant, 1, options)

        line_item.reload
        expect(line_item.quantity).to eq(2)
        expect(line_item).to eq(line_item2)
        expect(order.line_items.size).to eq(1)
        expect(line_item.line_item_personalisations.size).to eq(2)
      end

      it "should update order totals" do
        options1 = { personalisations: personalisation_params }
        options2 = { personalisations: personalisation_params2 }
        line_item = subject.add(variant, 1, options1)
        line_item = subject.add(variant, 1, options1)
        line_item2 = subject.add(variant, 1, options2)

        # 62.97 = 3 * 19.99
        expect(order.item_total.to_f).to eq(62.97)
        expect(order.total.to_f).to eq(62.97)
      end
    end

    context 'given a combination of personalisation and option' do
      let(:monogram) { create(:personalisation_monogram) }
      let(:personalisation_params) {[ Spree::LineItemPersonalisation.new(
        personalisation_id: monogram.id,
        amount: 1,
        data: { 'colour' => monogram.colours.first.id, 'initials' => 'DD'},
      )]}

      let(:variant_option1) { create(:variant) }

      let(:line_item_part_params) {[
        Spree::LineItemPart.new(
                       variant_id: variant_option1.id,
                       quantity:   3,
                       optional:   true,
                       price:      5,
                       currency:   'GBP'
                      )
      ]}

      it 'should only have one line item with same personalisations and option' do
        options = {
          personalisations: personalisation_params,
          parts:  line_item_part_params
        }
        line_item = subject.add(variant, 1, options)
        line_item2 = subject.add(variant, 1, options)

        line_item.reload
        expect(line_item.quantity).to eq(2)
        expect(line_item).to eq(line_item2)
        expect(order.line_items.size).to eq(1)
        expect(line_item.line_item_personalisations.size).to eq(1)
        expect(line_item.line_item_parts.size).to eq(1)
      end

      it 'should only have multiple line item with different personalisations' do
        options1 = { personalisations: personalisation_params }
        options2 = { parts: line_item_part_params }
        line_item = subject.add(variant, 1, options1)
        line_item2 = subject.add(variant, 1, options2)

        expect(line_item.quantity).to eq(1)
        expect(line_item2.quantity).to eq(1)
        expect(order.line_items.size).to eq(2)
        expect(line_item.line_item_personalisations.size).to eq(1)
        expect(line_item2.line_item_parts.size).to eq(1)
      end
    end
  end

  context "#build_line_item" do
    let(:variant_in_sale) { FactoryGirl.create(:variant_in_sale) }
    let(:monogram) { create(:personalisation_monogram) }

    context "prices" do
      it "should use normal variant price by default" do
        line_item = subject.send(:build_line_item, variant, 'I123', {} )

        expect(line_item.in_sale?).to be false
        expect(line_item.price).to eq(variant.price_normal_in(currency).amount)
        expect(line_item.normal_price).to eq(variant.price_normal_in(currency).amount)
      end

      it "should use normal_sale variant price when variant is in sale" do
        line_item = subject.send(:build_line_item, variant_in_sale, 'I123', {} )

        expect(line_item.in_sale?).to be true
        expect(line_item.price).to eq(variant_in_sale.price_normal_sale_in(currency).amount)
        expect(line_item.normal_price).to eq(variant_in_sale.price_normal_in(currency).amount)
      end


      it "should set the line item price to include the optional parts' prices" do
        variant = create(:variant)
        variant.price_normal_in('USD').amount = 60.00

        parts = [
          Spree::LineItemPart.new(
                         variant_id: create(:variant).id,
                         quantity:   2,
                         optional:   true,
                         price:      5,
                         currency:   'GBP'
                        ),
          Spree::LineItemPart.new(
                         variant_id: create(:variant).id,
                         quantity:   1,
                         optional:   true,
                         price:      5,
                         currency:   'GBP'
          )
        ]

        personalisations = [ Spree::LineItemPersonalisation.new(
          personalisation_id: monogram.id,
          amount: 10,
          data: { 'colour' => monogram.colours.first.id, 'initials' => 'DD'},
        )]

        options = { parts: parts, personalisations: personalisations }
        line_item = subject.send(:build_line_item, variant, 'I123', options )

        expect(line_item.price).to eq(85.00)
      end
    end
  end

  context "#eager_load" do
    let!(:line_item_1) { create(:line_item, order: order, quantity: 1)}

    before do
      order.reload
    end

    # This tests that the line_item than is in scope is the one
    # off the order.line_items collection, this is important as the
    # validations later work off of order.line_items which would not
    # reflect changes on line_item otherwise
    it "should load all the line_items without hitting" do
      lonely_line_item = Spree::LineItem.find(line_item_1.id)
      lonely_line_item.quantity = 99
      expect(order.line_items.first.quantity).to eq 1

      not_lonely_line_item = subject.send(:eager_load, lonely_line_item)
      not_lonely_line_item.quantity = 99
      expect(order.line_items.first.quantity).to eq 99
    end

  end

  context "#add_by_line_item" do
    let!(:line_item) { create(:line_item, order: order, quantity: 1)}

    before do
      allow(subject).to receive(:eager_load).with(line_item).and_return(line_item)
    end

    it "increases the quantity on the line_item" do
      subject.add_by_line_item(line_item, 2, {})
      expect(order.reload.line_items.first.quantity).to eq 3
    end
  end

  context "#remove_by_line_item" do
    before do
      allow(subject).to receive(:eager_load).with(line_item).and_return(line_item)
    end

    let(:line_item) { create(:line_item, order: order, quantity: 1)}

    it "decreases the quantity on the line_item" do
      subject.remove_by_line_item(line_item, 1, {})
      expect(order.reload.line_items.first).to be_nil
    end

    it "removes a line_item if quanity is 0" do
      subject.remove_by_line_item(line_item, 2, {})
      expect(order.reload.line_items.first).to be_nil
    end
  end

  # TODO: Add tests for removing line items with parts and target_id
  context "#remove" do
    context 'given a personalisation' do
      let(:monogram) { create(:personalisation_monogram) }
      let(:personalisation_params) {[ Spree::LineItemPersonalisation.new(
        personalisation_id: monogram.id,
        amount: 1,
        data: { 'colour' => monogram.colours.first.id, 'initials' => 'DD'},
      )]}

      let(:parts) { [
        Spree::LineItemPart.new(
          variant_id: create(:variant).id,
          quantity:   2,
          optional:   true,
          price:      5,
          currency:   'GBP'
        ),
        Spree::LineItemPart.new(
          variant_id: create(:variant).id,
          quantity:   1,
          optional:   true,
          price:      5,
          currency:   'GBP'
        )
      ] }

      it 'should reduce line item quantity' do
        options = { personalisations: personalisation_params, parts: parts }
        line_item = subject.add(variant, 3, options)
        subject.remove(variant, 1, options)

        expect(line_item.reload.quantity).to eq(2)

        expect(line_item.line_item_personalisations.size).to eq(1)
        expect(line_item.line_item_parts.size).to eq(2)
      end

      it 'should raise an error if line item does not exist' do
        options = { personalisations: personalisation_params, parts: parts }
        line_item = subject.add(variant, 3, options)

        expect { subject.remove(variant, 1, {}) }.to raise_error

        expect(line_item.reload.quantity).to eq(3)
      end

    end
  end
end
