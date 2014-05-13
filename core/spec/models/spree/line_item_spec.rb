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

  context '#add_parts' do

    let(:parts) {[
      OpenStruct.new(
        variant_id: create(:variant).id,
        quantity:   2,
        optional:   true,
        price:      5,
        currency:   'GBP'
      ),
      OpenStruct.new(
        variant_id: create(:variant).id,
        quantity:   1,
        optional:   true,
        price:      5,
        currency:   'GBP'
      )
    ]}

    it "should allow a part to be added" do
      line_item.add_parts(parts)
      expect(line_item.parts.size).to eq 2
      expect(line_item.parts.first.variant_id).to eq parts.first.variant_id
      expect(line_item.parts.first.quantity).to eq parts.first.quantity
      expect(line_item.parts.first.optional).to eq parts.first.optional
      expect(line_item.parts.first.price).to eq parts.first.price
      expect(line_item.parts.first.currency).to eq parts.first.currency
    end

    it "should deal with a nil price" do
      parts.first.price = nil
      line_item.add_parts(parts)
      expect(line_item.parts.size).to eq 2
      expect(line_item.parts.first.price).to eq BigDecimal.new(0)
    end

  end

  context '#add_personalisations' do


    let(:personalisations) {[
      OpenStruct.new(
        personalisation_id: 1,
        amount: 1,
        data: { 'colour' => 1, 'initials' => 'XX'},
      ),
      OpenStruct.new(
        personalisation_id: 1,
        amount: 2,
        data: { 'colour' => 1, 'initials' => 'WW'},
      ),
    ]}

    it "should allow a personalisation to be added" do
      line_item.add_personalisations(personalisations)
      expect(line_item.personalisations.size).to eq 2
      expect(line_item.personalisations.first.personalisation_id).to eq personalisations.first.personalisation_id
      expect(line_item.personalisations.first.amount).to eq personalisations.first.amount
      expect(line_item.personalisations.first.data).to eq personalisations.first.data
    end

    it "should deal with a nil amount" do
      personalisations.first.amount = nil
      line_item.add_personalisations(personalisations)
      expect(line_item.personalisations.size).to eq 2
      expect(line_item.personalisations.first.amount).to eq BigDecimal.new(0)
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

      Rails.logger.should_receive(:warn).with("The cost_price of variant id: #{variant10.id} is nil for line_item_part: #{lio.id}")
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

      Rails.logger.should_receive(:warn).with("The weight of variant id: #{variant10.id} is nil for line_item_part: #{lio.id}")
      expect(line_item.weight).to eq 22.0
    end

  end

  context '#save' do
    it 'touches the order' do
      line_item.order.should_receive(:touch)
      line_item.save
    end
  end

  context '#destroy' do
    before do
      line_item.save
    end

    it "fetches deleted products" do
      line_item.product.destroy
      expect(line_item.reload.product).to be_a Spree::Product
    end

    it "fetches deleted variants" do
      line_item.variant.destroy
      expect(line_item.reload.variant).to be_a Spree::Variant
    end

    it "returns inventory when a line item is destroyed" do
      Spree::OrderInventory.any_instance.should_receive(:verify).with(nil)
      line_item.destroy
    end

    it "destroys it's line_item_parts" do
      line_item.should_receive(:destroy_line_item_parts)
      line_item.destroy
    end

  end

  context "#save" do
    context "line item changes" do
      before do
        line_item.quantity = line_item.quantity + 1
      end

      it "triggers adjustment total recalculation" do
        line_item.should_receive(:recalculate_adjustments)
        line_item.save
      end

    end

    context "verify invetory" do
      before do
        line_item.save
      end

      it "should trigger if changes are made" do
        line_item.updated_at = Time.now
        Spree::OrderInventory.any_instance.should_receive(:verify)
        line_item.save
      end

      # Disabling this for now as there is a bug where the after_create is causing
      # changed? in line_item.update_inventory to not evaluate to true when 
      # changes have been made
      xit "should not trigger if changes are not made" do
        Spree::OrderInventory.any_instance.should_not_receive(:verify)
        line_item.save
      end

    end

    context "line item does not change" do
      it "does not trigger adjustment total recalculation" do
        line_item.should_not_receive(:recalculate_adjustments)
        line_item.save
      end
    end

  end

  context "#create" do
    let(:variant) { create(:variant) }

    before do
      create(:tax_rate, :zone => order.tax_zone, :tax_category => variant.tax_category)
    end

    it "verifies order_inventory" do
      Spree::OrderInventory.any_instance.should_receive(:verify)
      order.contents.add(variant)
    end

    context "when order has a tax zone" do
      before do
        order.tax_zone.should be_present
      end

      it "creates a tax adjustment" do
        order.contents.add(variant)
        line_item = order.find_line_item_by_variant(variant)
        line_item.adjustments.tax.count.should == 1
      end
    end

    context "when order does not have a tax zone" do
      before do
        order.bill_address = nil
        order.ship_address = nil
        order.save
        order.tax_zone.should be_nil
      end

      it "does not create a tax adjustment" do
        order.contents.add(variant)
        line_item = order.find_line_item_by_variant(variant)
        line_item.adjustments.tax.count.should == 0
      end

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
      expect(line_item.tax_category).to eq(line_item.variant.tax_category)
    end
  end

  describe '.discounted_amount' do
    it "returns the amount minus any discounts" do
      line_item.price = 10
      line_item.quantity = 2
      line_item.promo_total = -5
      line_item.discounted_amount.should == 15
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

  describe '.has_gift_card?' do
    it "returns false when has no gift card" do
      line_item.should_not be_has_gift_card
    end
    
    it "returns true when have a gift card" do
      line_item.product.stub(:product_type => 'gift_card')
      line_item.should be_has_gift_card
    end
  end

  describe ".sufficient_stock?" do
    it "variant out of stock across order" do
      allow(Spree::Stock::Quantifier).to receive(:can_supply_order?).and_return({errors: [{line_item_id: line_item.id}]})
      expect(line_item.sufficient_stock?).to be_false
    end

    it "variant in stock across order" do
      allow(Spree::Stock::Quantifier).to receive(:can_supply_order?).and_return({errors: []})
      expect(line_item.sufficient_stock?).to be_true
    end
  end

  context "has inventory (completed order so items were already unstocked)" do
    let(:order) { Spree::Order.create }
    let(:variant) { create(:variant) }

    context "line item with parts" do
      let(:container) { create(:variant) } 
      let(:part1) { create(:variant) }
      let(:part2) { create(:variant) }
      let(:parts) { [
       OpenStruct.new(variant_id: part1.id, optional: false, quantity: 2, price: 1),
       OpenStruct.new(variant_id: part2.id, optional: true, quantity: 1, price: 1),
      ] }
      
      before do
        container.stock_items.update_all count_on_hand: 50, backorderable: false
        part1.stock_items.update_all count_on_hand: 10, backorderable: false
        part2.stock_items.update_all count_on_hand: 5, backorderable: false

        order.contents.add(container, 5, nil, nil, parts)
        order.create_proposed_shipments
        order.finalize!        
      end

      it "allows to decrease kit quantity" do
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
        expect(line_item).to have(2).errors_on(:quantity)
      end
    end

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


  end

  context "saving with currency the same as order.currency" do
    it "saves the line_item" do
      expect { order.line_items.first.update_attributes!(currency: 'USD') }.to_not raise_error
    end
  end

  context "saving with currency different than order.currency" do
    it "doesn't save the line_item" do
      expect { order.line_items.first.update_attributes!(currency: 'AUD') }.to raise_error
    end
  end

end
