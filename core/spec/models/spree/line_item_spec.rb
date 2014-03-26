require 'spec_helper'

describe Spree::LineItem do
  let(:order) { create :order_with_line_items, line_items_count: 1 }
  let(:line_item) { order.line_items.first }

  describe "#item_sku" do
    subject {line_item}
    context "dynamic kit" do
      let(:variant10) { create(:variant, weight: 10) }
      let(:variant7)  { create(:variant, weight: 7) }

      let(:dynamic_kit_variant) {
        pdt = create(:product, product_type: 'kit')
        v = create(:variant, product_id: pdt.id, cost_price: 0, weight: 0)
        v.assembly_definition = Spree::AssemblyDefinition.create(variant_id: v.id)
        v
      }
      let(:part1) {dynamic_kit_variant.assembly_definition.parts.create(count: 1, product_id: variant10.product_id, optional: false)}
      let(:part2) {dynamic_kit_variant.assembly_definition.parts.create(count: 1, product_id: variant7.product_id, optional: true)}
      
      before do
        subject.variant = dynamic_kit_variant
        subject.line_item_parts.create(quantity: 1, price: 1, variant_id: variant10.id, optional: false, assembly_definition_part_id: part1.id)
        subject.line_item_parts.create(quantity: 1, price: 1, variant_id: variant7.id, optional: true, assembly_definition_part_id: part2.id)
        subject.save
      end
      its(:item_sku) { should eq [variant10.product.name, variant10.options_text].join(' - ')}
    end
    context "non - dynamic kit" do
      its(:item_sku) { should eq subject.variant.sku }
    end
  end

  context '#cost_price' do
    let(:variant10) { create(:variant, cost_price: 10) }
    let(:variant7)  { create(:variant, cost_price: 7) }
    let(:variant3)  { create(:variant, cost_price: 3) }
    let(:kit_variant) {
      pdt = create(:product, product_type: 'kit')
      v = create(:variant, product_id: pdt.id, cost_price: 2, weight: 0)
      v
    }
    before do
      line_item.quantity = 2
    end
    it "for simple variant" do
      line_item.variant = variant10
      expect(line_item.cost_price).to eq (2*10.0) #20.0
    end

    it "for kit variant no option" do
      line_item.variant = kit_variant
      expect(line_item.cost_price).to eq 4
    end

    it "for kit variant no option" do
      line_item.variant = kit_variant
      line_item.line_item_parts.create(quantity: 2, price: 1, variant_id: variant10.id, optional: false)
      line_item.line_item_parts.create(quantity: 1, price: 1, variant_id: variant7.id, optional: false)
      expect(line_item.cost_price).to eq 58.0
    end

    it "for kit variant with option" do
      line_item.variant = kit_variant
      line_item.line_item_parts.create(quantity: 2, price: 1, variant_id: variant10.id, optional: false)
      line_item.line_item_parts.create(quantity: 1, price: 1, variant_id: variant7.id, optional: false)
      line_item.line_item_parts.create(quantity: 1, price: 10, variant_id: variant3.id, optional: true)
      expect(line_item.cost_price).to eq 64.0
    end

    it "inherits parts master cost_price if any parts variant has nil cost_price" do
      line_item.variant = kit_variant
      variant10.cost_price = nil
      variant10.save
      line_item.line_item_parts.create(quantity: 2, price: 1, variant_id: variant10.id, optional: false)
      line_item.line_item_parts.create(quantity: 1, price: 1, variant_id: variant7.id, optional: false)
      line_item.line_item_parts.create(quantity: 1, price: 10, variant_id: variant3.id, optional: true)
      expect(line_item.cost_price).to eq 25.0
    end


    it "notifies if both part variant and master cost_price is nil and defaults to 0" do
      line_item.variant = kit_variant
      variant10.cost_price = nil
      variant10.product.master.cost_price = nil
      variant10.save
      variant10.product.master.save
      lio = line_item.line_item_parts.create(quantity: 2, price: 1, variant_id: variant10.id, optional: false)
      line_item.line_item_parts.create(quantity: 1, price: 1, variant_id: variant7.id, optional: false)
      line_item.line_item_parts.create(quantity: 1, price: 10, variant_id: variant3.id, optional: true)

      line_item.should_receive(:notify).with("The cost_price of variant id: #{variant10.id} is nil for line_item_part: #{lio.id}")
      expect(line_item.cost_price).to eq 24.0
    end

  end

  context '#weight' do
    let(:variant10) { create(:variant, weight: 10) }
    let(:variant7)  { create(:variant, weight: 7) }
    let(:variant3)  { create(:variant, weight: 3) }
    let!(:kit_variant) {
      pdt = create(:product, product_type: 'kit')
      v = create(:variant, product_id: pdt.id, cost_price: 0, weight: 1)
      v
    }
    before do
      line_item.quantity = 2
    end
    it "for simple variant" do
      line_item.variant = variant10
      expect(line_item.weight).to eq (2*10.0) #20.0
    end

    it "for kit variant no option" do
      line_item.variant = kit_variant
      expect(line_item.weight).to eq 2
    end

    it "for  kit variant with option" do
      line_item.variant = kit_variant
      line_item.line_item_parts.create(quantity: 2, price: 1, variant_id: variant10.id, optional: false)
      line_item.line_item_parts.create(quantity: 1, price: 1, variant_id: variant7.id, optional: false)
      line_item.line_item_parts.create(quantity: 1, price: 10, variant_id: variant3.id, optional: true)
      expect(line_item.weight).to eq 62.0
    end

    it "inherits parts master weight if any parts variant has nil weight" do
      line_item.variant = kit_variant
      variant10.weight = nil
      variant10.save
      line_item.line_item_parts.create(quantity: 2, price: 1, variant_id: variant10.id, optional: false)
      line_item.line_item_parts.create(quantity: 1, price: 1, variant_id: variant7.id, optional: false)
      line_item.line_item_parts.create(quantity: 1, price: 10, variant_id: variant3.id, optional: true)
      expect(line_item.weight).to eq 23.0
    end


    it "notifies if both part variant and master weight is nil and defaults to 0" do
      line_item.variant = kit_variant
      variant10.weight = nil
      variant10.product.master.weight = nil
      variant10.save
      variant10.product.master.save
      lio = line_item.line_item_parts.create(quantity: 2, price: 1, variant_id: variant10.id, optional: false)
      line_item.line_item_parts.create(quantity: 1, price: 1, variant_id: variant7.id, optional: false)
      line_item.line_item_parts.create(quantity: 1, price: 10, variant_id: variant3.id, optional: true)

      line_item.should_receive(:notify).with("The weight of variant id: #{variant10.id} is nil for line_item_part: #{lio.id}")
      expect(line_item.weight).to eq 22.0
    end

  end

  context '#save' do
    it 'should update inventory, totals, and tax' do
      # Regression check for #1481
      line_item.order.should_receive(:create_tax_charge!)
      line_item.order.should_receive(:update!)
      line_item.quantity = 2
      line_item.save
    end
  end

  context '#destroy' do
    # Regression test for #1481
    it "applies tax adjustments" do
      line_item.order.should_receive(:create_tax_charge!)
      line_item.destroy
    end

    it "fetches deleted products" do
      line_item.product.destroy
      expect(line_item.reload.product).to be_a Spree::Product
    end

    it "fetches deleted variants" do
      line_item.variant.destroy
      expect(line_item.reload.variant).to be_a Spree::Variant
    end
  end

  # Test for #3391
  context '#copy_price' do
    it "copies over a variant's prices" do
      line_item.price = nil
      line_item.cost_price = nil
      line_item.currency = nil
      line_item.copy_price
      variant = line_item.variant
      line_item.price.should == variant.price
      line_item.cost_price.should == variant.cost_price
      line_item.currency.should == variant.currency
    end
  end

  # Test for #3481
  context '#copy_tax_category' do
    it "copies over a variant's tax category" do
      line_item.tax_category = nil
      line_item.copy_tax_category
      line_item.tax_category.should == line_item.variant.product.tax_category
    end
  end

  describe '.currency' do
    it 'returns the globally configured currency' do
      line_item.currency == 'USD'
    end
  end

  describe ".money" do
    before do
      line_item.price = 3.50
      line_item.quantity = 2
    end

    it "returns a Spree::Money representing the total for this line item" do
      line_item.money.to_s.should == "$7.00"
    end
  end

  describe '.single_money' do
    before { line_item.price = 3.50 }
    it "returns a Spree::Money representing the price for one variant" do
      line_item.single_money.to_s.should == "$3.50"
    end
  end

  context "has inventory (completed order so items were already unstocked)" do
    let(:order) { Spree::Order.create }
    let(:variant) { create(:variant) }

    context "nothing left on stock" do
      before do
        variant.stock_items.update_all count_on_hand: 5, backorderable: false
        order.contents.add(variant, 5)
        order.create_proposed_shipments
        order.finalize!
      end

      it "allows to decrease item quantity" do
        line_item = order.line_items.first
        line_item.quantity -= 1
        line_item.target_shipment = order.shipments.first

        line_item.save
        expect(line_item).to have(0).errors_on(:quantity)
      end

      it "doesnt allow to increase item quantity" do
        line_item = order.line_items.first
        line_item.quantity += 2
        line_item.target_shipment = order.shipments.first

        line_item.save
        expect(line_item).to have(1).errors_on(:quantity)
      end
    end

    context "2 items left on stock" do
      before do
        variant.stock_items.update_all count_on_hand: 7, backorderable: false
        order.contents.add(variant, 5)
        order.create_proposed_shipments
        order.finalize!
      end

      it "allows to increase quantity up to stock availability" do
        line_item = order.line_items.first
        line_item.quantity += 2
        line_item.target_shipment = order.shipments.first

        line_item.save
        expect(line_item).to have(0).errors_on(:quantity)
      end

      it "doesnt allow to increase quantity over stock availability" do
        line_item = order.line_items.first
        line_item.quantity += 3
        line_item.target_shipment = order.shipments.first

        line_item.save
        expect(line_item).to have(1).errors_on(:quantity)
      end
    end

    context "Class Methods" do
      let(:monogram) { create(:personalisation_monogram) }

      it "generate_uuid" do
        colour_id = monogram.colours.first.id
        personalisations = [
          {
            personalisation_id: monogram.id,
            amount: 1,
            data: { 'colour' => colour_id, 'initials' => 'XX'},
          },
          {
            personalisation_id: monogram.id,
            amount: 2,
            data: { 'colour' => colour_id, 'initials' => 'WW'},
          },
        ]

        options_with_qty = [
          [FactoryGirl.create(:variant), 1],
          [FactoryGirl.create(:variant), 1],
        ]

        options_uuid = "#{options_with_qty[0][0].id}-#{options_with_qty[0][1]}:#{options_with_qty[1][0].id}-#{options_with_qty[1][1]}"
        personalisation_uuid = "#{monogram.id}-colour-#{colour_id}-initials-WW:#{monogram.id}-colour-#{colour_id}-initials-XX"

        expected_uuid = "#{variant.id}_#{personalisation_uuid}_#{options_uuid}"
        actual_uuid = Spree::LineItem.generate_uuid( variant, options_with_qty, personalisations )

        expect(actual_uuid).to eq(expected_uuid)
      end
    end

  end
end
