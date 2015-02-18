require 'spec_helper'

describe Spree::LineItem, :type => :model do
  let(:order) { create :order_with_line_items, line_items_count: 1 }
  let(:line_item) { order.line_items.first }

  describe "#item_sku" do
    subject {line_item}
    context "dynamic kit" do
      # sku's are important as we do a sort on the sku when generating
      # the item_sku
      let(:variant11) { create(:variant, weight: 11, sku: 'c') }
      let(:variant10) { create(:variant, weight: 10, sku: 'a') }
      let(:variant8)  { create(:variant, weight: 8, sku: 'b') }
      let(:variant7)  { create(:variant, weight: 7) }
      let(:option_type)  { create(:option_type) }

      let(:dynamic_kit_variant) {
        pdt = create(:product, product_type: create(:product_type_kit))
        v = create(:variant, product_id: pdt.id, cost_price: 0, weight: 0)
        v.assembly_definition = Spree::AssemblyDefinition.create(variant_id: v.id)
        v
      }
      let(:part1) {dynamic_kit_variant.assembly_definition.parts.create(count: 1, product_id: variant11.product_id, optional: false, displayable_option_type: option_type)}
      let(:part2) {dynamic_kit_variant.assembly_definition.parts.create(count: 1, product_id: variant10.product_id, optional: false, displayable_option_type: option_type)}
      let(:part3) {dynamic_kit_variant.assembly_definition.parts.create(count: 1, product_id: variant8.product_id, optional: false, displayable_option_type: option_type)}
      let(:part4) {dynamic_kit_variant.assembly_definition.parts.create(count: 1, product_id: variant7.product_id, optional: true, displayable_option_type: option_type)}

      before do
        subject.variant = dynamic_kit_variant
        subject.line_item_parts.create(quantity: 1, price: 1, variant_id: variant11.id, optional: false, assembly_definition_part_id: part1.id)
        subject.line_item_parts.create(quantity: 1, price: 1, variant_id: variant10.id, optional: false, assembly_definition_part_id: part2.id)
        subject.line_item_parts.create(quantity: 2, price: 1, variant_id: variant8.id, optional: false, assembly_definition_part_id: part3.id)
        subject.line_item_parts.create(quantity: 1, price: 1, variant_id: variant7.id, optional: true, assembly_definition_part_id: part4.id)
        subject.save
      end

      it "is made up of the part skus" do
        expect(subject.item_sku).to eq "#{subject.variant.sku} [#{variant10.sku}, #{variant8.sku}, #{variant11.sku}]"
      end
    end
    context "non - dynamic kit" do
      it "is equal to the variant sku" do
        expect(subject.item_sku).to eq "#{subject.variant.sku}"
      end
    end
  end

  context '#cost_price' do
    let(:variant10) { create(:variant, cost_price: 10) }
    let(:variant7)  { create(:variant, cost_price: 7) }
    let(:variant3)  { create(:variant, cost_price: 3) }
    let(:kit_variant) {
      pdt = create(:product, product_type: create(:product_type_kit))
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
      variant10.update_column(:cost_price, nil)
      line_item.line_item_parts.create(quantity: 2, price: 1, variant_id: variant10.id, optional: false)
      line_item.line_item_parts.create(quantity: 1, price: 1, variant_id: variant7.id, optional: false)
      line_item.line_item_parts.create(quantity: 1, price: 10, variant_id: variant3.id, optional: true)
      # 2 * 17 ( variant10.product.master.cost_price ) 
      # 1 * 7 ( variant7.cost_price ) 
      # 1 * 3 ( variant3.cost_price ) 
      # => 44
      # 1 * 2 ( line_item.variant.cost_price )
      # => 46
      # * 2 ( quantity of 2 )
      # => 92
      expect(line_item.cost_price).to eq 92.0
    end


    it "notifies if both part variant and master cost_price is nil and defaults to 0" do
      line_item.variant = kit_variant
      variant10.update_column(:cost_price, nil)
      variant10.product.master.update_column(:cost_price, nil)
      lio = line_item.line_item_parts.create(quantity: 2, price: 1, variant_id: variant10.id, optional: false)
      line_item.line_item_parts.create(quantity: 1, price: 1, variant_id: variant7.id, optional: false)
      line_item.line_item_parts.create(quantity: 1, price: 10, variant_id: variant3.id, optional: true)

      expect(Rails.logger).to receive(:warn).with("The cost_price of variant id: #{variant10.id} is nil for line_item_part: #{lio.id}")
      expect(line_item.cost_price).to eq 24.0
    end
  end

  context '#weight' do
    let(:variant10) { create(:variant, weight: 10) }
    let(:variant7)  { create(:variant, weight: 7) }
    let(:variant3)  { create(:variant, weight: 3) }
    let!(:kit_variant) {
      pdt = create(:product, product_type: create(:product_type_kit))
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
      variant10.update_column(:weight, nil)
      line_item.line_item_parts.create(quantity: 2, price: 1, variant_id: variant10.id, optional: false)
      line_item.line_item_parts.create(quantity: 1, price: 1, variant_id: variant7.id, optional: false)
      line_item.line_item_parts.create(quantity: 1, price: 10, variant_id: variant3.id, optional: true)
      expect(line_item.weight).to eq 23.0
    end


    it "notifies if both part variant and master weight is nil and defaults to 0" do
      line_item.variant = kit_variant
      variant10.update_column(:weight, nil)
      variant10.product.master.update_column(:weight, nil)
      lio = line_item.line_item_parts.create(quantity: 2, price: 1, variant_id: variant10.id, optional: false)
      line_item.line_item_parts.create(quantity: 1, price: 1, variant_id: variant7.id, optional: false)
      line_item.line_item_parts.create(quantity: 1, price: 10, variant_id: variant3.id, optional: true)

      expect(Rails.logger).to receive(:warn).with("The weight of variant id: #{variant10.id} is nil for line_item_part: #{lio.id}")
      expect(line_item.weight).to eq 22.0
    end

  end

  context '#save' do
    it 'touches the order' do
      expect(line_item.order).to receive(:touch)
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
      expect_any_instance_of(Spree::OrderInventory).to receive(:verify)
      line_item.destroy
    end

    it "deletes inventory units" do
      allow(line_item.order).to receive(:completed?).and_return true
      expect { line_item.destroy }.to change { line_item.inventory_units.count }.from(1).to(0)
    end
  end

  context "updates bundle product line item" do
    let(:parts) { (1..2).map { create(:line_item_part) } }

    before do
      line_item.parts << parts
      order.create_proposed_shipments
      order.finalize!
    end

    it "destroys units along with line item" do
      expect(Spree::OrderInventory.new(line_item.order, line_item).inventory_units).not_to be_empty
      line_item.destroy_along_with_units
      expect(Spree::InventoryUnit.where(line_item_id: line_item.id).to_a).to be_empty
    end

    it "destroys its line_item_parts" do
      line_item.destroy
      expect { parts.first.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { parts.last.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context "#save" do
    context "line item changes" do
      before do
        line_item.quantity = line_item.quantity + 1
      end

      it "triggers adjustment total recalculation" do
        expect(line_item).to receive(:update_tax_charge) # Regression test for https://github.com/spree/spree/issues/4671
        expect(line_item).to receive(:recalculate_adjustments)
        line_item.save
      end

    end

    context "verify invetory" do
      before do
        line_item.save
      end

      it "should trigger if changes are made" do
        line_item.updated_at = Time.now
        expect_any_instance_of(Spree::OrderInventory).to receive(:verify)
        line_item.save
      end

      # Disabling this for now as there is a bug where the after_create is causing
      # changed? in line_item.update_inventory to not evaluate to true when
      # changes have been made
      # xit "should not trigger if changes are not made" do
      #   Spree::OrderInventory.any_instance.should_not_receive(:verify)
      #   line_item.save
      # end

    end

    context "line item does not change" do
      it "does not trigger adjustment total recalculation" do
        expect(line_item).not_to receive(:recalculate_adjustments)
        line_item.save
      end
    end

    context "target_shipment is provided" do
      it "verifies inventory" do
        line_item.target_shipment = Spree::Shipment.new
        expect_any_instance_of(Spree::OrderInventory).to receive(:verify)
        line_item.save
      end
    end
  end

  context "#create" do
    let(:variant) { create(:variant) }

    before do
      variant.price_normal_in('USD').amount = 19.99
      create(:tax_rate, :zone => order.tax_zone, :tax_category => variant.tax_category)
    end

    it "verifies order_inventory" do
      expect_any_instance_of(Spree::OrderInventory).to receive(:verify)
      order.contents.add(variant)
    end

    context "when order has a tax zone" do
      before do
        expect(order.tax_zone).to be_present
      end

      it "creates a tax adjustment" do
        line_item = order.contents.add(variant)
        expect(line_item.adjustments.tax.count).to eq(1)
      end
    end

    context "when order does not have a tax zone" do
      before do
        order.bill_address = nil
        order.ship_address = nil
        order.save
        expect(order.reload.tax_zone).to be_nil
      end

      it "does not create a tax adjustment" do
        line_item = order.contents.add(variant)
        expect(line_item.adjustments.tax.count).to eq(0)
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
      expect(line_item.price).to eq(variant.price_normal_in(order.currency).amount)
      expect(line_item.cost_price).to eq(variant.cost_price)
      expect(line_item.currency).to eq(variant.currency)
    end
  end
  # TODO, if it is in the sale, we should change the price to reflect that

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
      expect(line_item.discounted_amount).to eq(15)
    end
  end

  describe "#discounted_money" do
    it "should return a money object with the discounted amount" do
      expect(line_item.discounted_money.to_s).to eq "$10.00"
    end
  end

  describe '.currency' do
    it 'returns the globally configured currency' do
      line_item.currency == 'USD'
    end
  end

  describe ".normal_display_amount" do
    before do
      line_item.price = 3.50
      line_item.normal_price = 3.50
      line_item.quantity = 2
    end

    it "returns a Spree::Money representing the total for this line item" do
      expect(line_item.normal_display_amount.to_s).to eq("$7.00")
    end

  end

  describe ".sale_display_amount" do
    before do
      line_item.price = 2.50
      line_item.normal_price = 3.50
      line_item.quantity = 2
    end

    it "returns a Spree::Money representing the total for this line item" do
      expect(line_item.sale_display_amount.to_s).to eq("$7.00")
    end

    it "returns a Spree::Money representing the total for this line item when in the sale" do
      line_item.in_sale = true
      expect(line_item.sale_display_amount.to_s).to eq("$5.00")
    end

  end


  describe ".money" do
    before do
      line_item.price = 3.50
      line_item.quantity = 2
    end

    it "returns a Spree::Money representing the total for this line item" do
      expect(line_item.money.to_s).to eq("$7.00")
    end
  end

  describe '.single_money' do
    before { line_item.price = 3.50 }
    it "returns a Spree::Money representing the price for one variant" do
      expect(line_item.single_money.to_s).to eq("$3.50")
    end
  end

  describe '.has_gift_card?' do
    it "returns false when has no gift card" do
      expect(line_item).not_to be_has_gift_card
    end

    it "returns true when have a gift card" do
      line_item.product.product_type = create(:product_type_gift_card)
      expect(line_item).to be_has_gift_card
    end
  end

  describe ".sufficient_stock?" do
    let(:line_item) { Spree::LineItem.new }

    it "variant out of stock across order" do
      line_item.errors[:quantity] << "Insufficient stock error"
      allow_any_instance_of(Spree::Stock::AvailabilityValidator).to receive(:validate)
      expect(line_item.sufficient_stock?).to be false
    end

    it "variant in stock across order" do
      allow_any_instance_of(Spree::Stock::AvailabilityValidator).to receive(:validate)
      expect(line_item.sufficient_stock?).to be true
    end
  end

  context "has inventory (completed order so items were already unstocked)" do
    let(:order) { Spree::Order.create(email: 'spree@example.com') }
    let(:variant) { create(:variant) }
    let(:supplier) { create(:supplier) }

    context "line item with parts" do
      let(:container) { create(:variant) }
      let(:part1) { create(:variant) }
      let(:part2) { create(:variant) }
      let(:parts) { [
       Spree::LineItemPart.new(variant_id: part1.id, optional: false, quantity: 2, price: 1),
       Spree::LineItemPart.new(variant_id: part2.id, optional: true, quantity: 1, price: 1),
      ] }

      before do
        create(:product_type_gift_card)
        container.stock_items.update_all count_on_hand: 50, backorderable: false, supplier_id: supplier.id
        part1.stock_items.update_all count_on_hand: 10, backorderable: false, supplier_id: supplier.id
        part2.stock_items.update_all count_on_hand: 5, backorderable: false, supplier_id: supplier.id

        order.contents.add(container, 5, parts: parts)
        order.create_proposed_shipments
        order.finalize!
      end

      it "allows to decrease kit quantity" do
        line_item = order.line_items.first
        line_item.quantity -= 1
        line_item.target_shipment = order.shipments.first

        line_item.save
        expect(line_item.errors[:quantity].size).to eq(0)
      end

      it "doesnt allow to increase item quantity" do
        line_item = order.line_items.first
        line_item.quantity += 2
        line_item.target_shipment = order.shipments.first

        line_item.save
        expect(line_item.errors[:quantity].size).to eq(1)
      end
    end

    context "nothing left on stock" do
      before do
        variant.stock_items.update_all count_on_hand: 5, backorderable: false, supplier_id: supplier.id
        order.contents.add(variant, 5, {})
        order.create_proposed_shipments
        order.finalize!
      end

      it "allows to decrease item quantity" do
        line_item = order.line_items.first
        line_item.quantity -= 1
        line_item.target_shipment = order.shipments.first

        line_item.save
        expect(line_item.errors_on(:quantity).size).to eq(0)
      end

      it "doesnt allow to increase item quantity" do
        line_item = order.line_items.first
        line_item.quantity += 2
        line_item.target_shipment = order.shipments.first

        line_item.save
        expect(line_item.errors_on(:quantity).size).to eq(1)
      end
    end

    context "2 items left on stock" do
      before do
        variant.stock_items.update_all count_on_hand: 7, backorderable: false, supplier_id: supplier.id
        order.contents.add(variant, 5)
        order.create_proposed_shipments
        order.finalize!
      end

      it "allows to increase quantity up to stock availability" do
        line_item = order.line_items.first
        line_item.quantity += 2
        line_item.target_shipment = order.shipments.first

        line_item.save
        expect(line_item.errors_on(:quantity).size).to eq(0)
      end

      it "doesnt allow to increase quantity over stock availability" do
        line_item = order.line_items.first
        line_item.quantity += 3
        line_item.target_shipment = order.shipments.first

        line_item.save
        expect(line_item.errors_on(:quantity).size).to eq(1)
      end
    end


  end

  context "currency same as order.currency" do
    it "is a valid line item" do
      line_item = order.line_items.first
      line_item.currency = order.currency
      line_item.valid?

      expect(line_item.error_on(:currency).size).to eq(0)
    end
  end

  context "currency different than order.currency" do
    it "is not a valid line item" do
      line_item = order.line_items.first
      line_item.currency = "no currency"
      line_item.valid?

      expect(line_item.error_on(:currency).size).to eq(1)
    end
  end

  describe "#options=" do
    it "can handle updating a blank line item with no order" do
      line_item.options = { price: 123 }
    end

    it "updates the data provided in the options" do
      line_item.options = { price: 123 }
      expect(line_item.price).to eq 123
    end

    # This is disabled for the time being, as we set the price
    # in the order_contents model for line item options
    #
    #it "updates the price based on the options provided" do
    #  expect(line_item).to receive(:gift_wrap=).with(true)
    #  expect(line_item.variant).to receive(:gift_wrap_price_modifier_amount_in).with("USD", true).and_return 1.99
    #  line_item.options = { gift_wrap: true }
    #  expect(line_item.price).to eq 21.98
    #end
  end
end
