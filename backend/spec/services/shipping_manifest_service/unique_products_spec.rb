require "spec_helper"
describe Spree::ShippingManifestService::UniqueProducts do
  subject do
    described_class.run(
      order: order, shipping_costs: shipping_costs, order_total: order_total)
  end

  let(:order) { create(:order, total: 110, ship_total: 10, currency: "USD") }
  let(:shipping_costs) { BigDecimal.new(10) }
  let(:order_total) { BigDecimal.new(110) }

  let(:variant) { create(:base_variant) }
  let(:supplier) { create(:supplier) }
  let(:line_item_1) { create(:base_line_item, order: order, variant: variant) }

  context "Non assembly" do
    let!(:inventory_unit_1) do
      create(:base_inventory_unit,
             line_item: line_item_1,
             order: order,
             variant: variant,
             supplier: supplier)
    end

    it "returns valid paramters" do
      unique_products = subject.result
      expect(unique_products.count).to eq 1
      expect(unique_products.first[:mid_code]).to eq supplier.mid_code
      expect(unique_products.first[:quantity]).to eq 1
      expect(unique_products.first[:total_price].to_f).to eq 100.00
      expect(unique_products.first[:product]).to eq variant.product
      expect(unique_products.first[:group]).to eq variant.product.product_group
    end

    context "no supplier" do
      let!(:inventory_unit_1) do
        create(:base_inventory_unit, line_item: line_item_1, order: order, variant: variant)
      end

      it "retuns errors" do
        expect(subject.valid?).to be false
        expected = "Missing supplier for product: #{variant.product.name} (ID: #{variant.product.id}) for order ##{order.number}"
        expect(subject.errors.full_messages.to_sentence).to eq expected
      end
    end

    context "with non physical line items" do
      let(:digital_product) { create(:product, product_type: create(:product_type_gift_card)) }
      let(:line_item_1) { create(:base_line_item, variant: digital_product.master, order: order) }

      it "ignores them" do
        unique_products = subject.result
        expect(unique_products.count).to eq 0
      end
    end

    context "with operational line item" do
      let(:operational_product) { create(:product, product_type: create(:product_type_packaging)) }
      let(:line_item_1) do
        create(:base_line_item, variant: operational_product.master, order: order)
      end

      it "ignores them" do
        unique_products = subject.result
        expect(unique_products.count).to eq 0
      end
    end

    context "2 line items" do
      let(:variant_2) { create(:base_variant) }
      let(:line_item_2) { create(:base_line_item, order: order, variant: variant_2) }
      let!(:inventory_unit_2) do
        create(:base_inventory_unit,
               line_item: line_item_2,
               order: order,
               variant: variant_2,
               supplier: supplier)
      end

      it "returns valid paramters" do
        unique_products = subject.result
        expect(unique_products.count).to eq 2
        expect(unique_products.first[:mid_code]).to eq supplier.mid_code
        expect(unique_products.first[:quantity]).to eq 1
        expect(unique_products.first[:total_price].to_f).to eq 50.00
        expect(unique_products.first[:product]).to eq variant.product
        expect(unique_products.first[:group]).to eq variant.product.product_group

        expect(unique_products.last[:mid_code]).to eq supplier.mid_code
        expect(unique_products.last[:quantity]).to eq 1
        expect(unique_products.last[:total_price].to_f).to eq 50.00
        expect(unique_products.last[:product]).to eq variant_2.product
        expect(unique_products.last[:group]).to eq variant_2.product.product_group
      end
    end

    context "quanity of 2" do
      let(:line_item_1) { create(:base_line_item, variant: variant, order: order, quantity: 2) }

      context "can be satisfied by the same supplier" do
        before do
          create(:base_inventory_unit,
                 line_item: line_item_1,
                 order: order,
                 variant: variant,
                 supplier: supplier)
        end

        it "returns valid paramters" do
          unique_products = subject.result
          expect(unique_products.count).to eq 1
          expect(unique_products.first[:mid_code]).to eq supplier.mid_code
          expect(unique_products.first[:quantity]).to eq 2
          expect(unique_products.first[:total_price].to_f).to eq 100.00
          expect(unique_products.first[:product]).to eq variant.product
          expect(unique_products.first[:group]).to eq variant.product.product_group
        end
      end

      context "needs to be satisfied by different suppliers" do
        let(:supplier_2) { create(:supplier, mid_code: "supplier_2_mid_code") }

        before do
          create(:base_inventory_unit,
                 line_item: line_item_1,
                 order: order,
                 variant: variant,
                 supplier: supplier_2)
        end

        it "returns valid paramters" do
          unique_products = subject.result

          expect(unique_products.count).to eq 2

          up1 = unique_products.detect { |x| x[:mid_code] ==  supplier.mid_code }
          expect(up1).to_not be_nil
          expect(up1[:quantity]).to eq 1
          expect(up1[:total_price].to_f).to eq 50.00
          expect(up1[:product]).to eq variant.product
          expect(up1[:group]).to eq variant.product.product_group

          up2 = unique_products.detect { |x| x[:mid_code] ==  supplier_2.mid_code }
          expect(up2).to_not be_nil
          expect(up2[:quantity]).to eq 1
          expect(up2[:total_price].to_f).to eq 50.00
          expect(up2[:product]).to eq variant.product
          expect(up2[:group]).to eq variant.product.product_group
        end
      end
    end
  end

  # Please note an assembly does not create a container inventory unit
  context "Assembly" do
    let!(:line_item_1) do
      create(:base_line_item, variant: variant, order: order, quantity: 2, price: 50)
    end
    let(:variant_2) { create(:variant) }
    let(:supplier_2) { create(:supplier, mid_code: "supplier_2_mid_code") }
    let(:adp1) { create(:assembly_definition_part, position: 1) }
    let(:adp2) { create(:assembly_definition_part, position: 2) }
    let(:adp3) { create(:assembly_definition_part, position: 3) }
    let!(:part1) do
      create(:line_item_part,
             optional: false,
             line_item: line_item_1,
             quantity: 2,
             variant: variant_2,
             price: 10.0,
             assembly_definition_part: adp1
            )
    end

    before do
      line_item_1.quantity.times do
        part1.quantity.times do
          create(:base_inventory_unit,
                 line_item: part1.line_item,
                 order: order,
                 variant: part1.variant,
                 supplier: supplier_2,
                 line_item_part: part1
                )
        end
      end
    end

    it "processes the parts correctly" do
      unique_products = subject.result
      expect(unique_products.count).to eq 1
      up = unique_products.first

      expect(up[:mid_code]).to eq supplier_2.mid_code
      expect(up[:quantity]).to eq 4
      expect(up[:total_price].to_f).to eq 100.00
      expect(up[:product]).to eq variant_2.product
      expect(up[:group]).to eq variant_2.product.product_group
    end

    context "with a container part" do
      let(:container_variant) { create(:base_variant) }
      let(:part3_variant) { create(:base_variant) }
      let!(:part2) do
        create(:line_item_part,
               optional: false,
               line_item: line_item_1,
               quantity: 2,
               price: 10.00,
               variant: container_variant,
               container: true,
               assembly_definition_part: adp2)
      end
      let!(:part3) do
        create(:line_item_part,
               optional: true,
               line_item: line_item_1,
               quantity: 2,
               price: 5.00,
               variant: part3_variant,
               assembly_definition_part: adp3)
      end

      before do
        line_item_1.quantity.times do
          part3.quantity.times do
            create(:base_inventory_unit,
                   line_item: part3.line_item,
                   order: order,
                   variant: part3.variant,
                   supplier: supplier_2,
                   line_item_part: part2
                  )
          end
        end
      end

      it "ignores the container parts" do
        unique_products = subject.result

        expect(unique_products.count).to eq 2
        up1 = unique_products.detect { |x| x[:product] ==  variant_2.product }
        up2 = unique_products.detect { |x| x[:product] ==  part3_variant.product }

        expect(up1[:mid_code]).to eq supplier_2.mid_code
        expect(up1[:quantity]).to eq 4
        expect(up1[:total_price].to_f).to eq 50.00
        expect(up1[:group]).to eq variant_2.product.product_group

        expect(up2[:mid_code]).to eq supplier_2.mid_code
        expect(up2[:quantity]).to eq 4
        expect(up2[:total_price].to_f).to eq 50.00
        expect(up2[:group]).to eq part3_variant.product.product_group
      end
    end

    context "assemble true" do
      let(:part2_variant) { create(:base_variant) }
      let(:part3_variant) { create(:base_variant) }
      let!(:part2) do
        create(:line_item_part,
               line_item: line_item_1,
               quantity: 2,
               price: 24.00,
               variant: part2_variant,
               assembly_definition_part: adp2)
      end
      let!(:part3) do
        create(:line_item_part,
               line_item: line_item_1,
               quantity: 2,
               price: 5.00,
               variant: part3_variant,
               assembly_definition_part: adp3)
      end

      before do
        variant.product.update_column(:assemble, true)
        line_item_1.quantity.times do
          part2.quantity.times do
            create(:base_inventory_unit,
                   line_item: part2.line_item,
                   order: order,
                   variant: part2.variant,
                   supplier: supplier_2,
                   line_item_part: part2
                  )
          end
          part3.quantity.times do
            create(:base_inventory_unit,
                   line_item: part3.line_item,
                   order: order,
                   variant: part3.variant,
                   supplier: supplier_2,
                   line_item_part: part2
                  )
          end
        end
        line_item_1.product.assembly_definition_parts = [adp1, adp2, adp3]
      end

      it "uses the first line_item_part as the main part" do
        unique_products = subject.result

        expect(unique_products.count).to eq 1
        up1 = unique_products.detect { |x| x[:product] ==  part1.product }

        expect(up1[:mid_code]).to eq supplier_2.mid_code
        expect(up1[:quantity]).to eq 4
        expect(up1[:total_price].to_f).to eq 100.00
        expect(up1[:group]).to eq part2_variant.product.product_group
      end

      context "line_item has a main inventory unit" do
        let!(:inventory_unit_1) do
          create(:base_inventory_unit,
                 line_item: line_item_1,
                 order: order,
                 variant: variant_2,
                 supplier: supplier)
        end

        it "uses line line_item as the main part" do
          unique_products = subject.result

          expect(unique_products.count).to eq 1
          up1 = unique_products.detect { |x| x[:product] ==  variant_2.product }

          expect(up1[:mid_code]).to eq supplier.mid_code
          expect(up1[:quantity]).to eq 1
          expect(up1[:total_price].to_f).to eq 100.00
          expect(up1[:group]).to eq variant_2.product.product_group
        end
      end
    end

    context "multiple required parts" do
      let(:variant_3) { create(:variant) }
      let!(:part2) do
        create(:line_item_part,
               optional: false,
               line_item: line_item_1,
               quantity: 2,
               variant: variant_3,
               price: 10.0,
               assembly_definition_part: adp2)
      end

      before do
        line_item_1.quantity.times do
          part2.quantity.times do
            create(:base_inventory_unit,
                   line_item: part2.line_item,
                   order: order,
                   variant: part2.variant,
                   supplier: supplier_2,
                   line_item_part: part2
                  )
          end
        end
        order.updater.update_item_total
      end

      it "breaks up the total price proportionally across the parts" do
        unique_products = subject.result

        expect(unique_products.count).to eq 2
        up1 = unique_products.detect { |x| x[:product] ==  variant_2.product }
        up2 = unique_products.detect { |x| x[:product] ==  variant_3.product }

        expect(up1[:mid_code]).to eq supplier_2.mid_code
        expect(up1[:quantity]).to eq 4
        expect(up1[:total_price].to_f).to eq 50.00
        expect(up1[:group]).to eq variant_2.product.product_group

        expect(up2[:mid_code]).to eq supplier_2.mid_code
        expect(up2[:quantity]).to eq 4
        expect(up2[:total_price].to_f).to eq 50.00
        expect(up2[:group]).to eq variant_3.product.product_group
      end
    end

    context "suppliers" do
      let(:supplier_3) { create(:supplier, mid_code: "supplier_3_mid_code") }

      before do
        # update one of the inventory items with the a new supplier
        ius = line_item_1.inventory_units.select { |x| x.variant == part1.variant }
        ius.last.update_column(:supplier_id, supplier_3.id)
      end

      it "splits the parts up and attributes them to the correct gang memebers" do
        unique_products = subject.result

        expect(unique_products.count).to eq 2
        up1 = unique_products.detect { |x| x[:mid_code] ==  supplier_2.mid_code }
        up2 = unique_products.detect { |x| x[:mid_code] ==  supplier_3.mid_code }

        expect(up1[:quantity]).to eq 3
        expect(up1[:total_price].to_f).to eq 75.00
        expect(up1[:group]).to eq variant_2.product.product_group
        expect(up1[:product]).to eq variant_2.product

        expect(up2[:quantity]).to eq 1
        expect(up2[:total_price].to_f).to eq 25.00
        expect(up2[:product]).to eq variant_2.product
        expect(up1[:group]).to eq variant_2.product.product_group
      end
    end

    context "optional" do
      let(:variant_3) { create(:variant) }
      let!(:part2) do
        create(:line_item_part,
               optional: true,
               line_item: line_item_1,
               quantity: 2,
               variant: variant_3,
               price: 2.0,
               assembly_definition_part: adp2)
      end

      before do
        line_item_1.quantity.times do
          part2.quantity.times do
            create(:base_inventory_unit,
                   line_item: part2.line_item,
                   order: order,
                   variant: part2.variant,
                   supplier: supplier_2,
                   line_item_part: part2
                  )
          end
        end

        order.updater.update_item_total
      end

      it "breaks up the total price proportionally across the parts" do
        unique_products = subject.result

        expect(unique_products.count).to eq 2
        up1 = unique_products.detect { |x| x[:product] ==  variant_2.product }
        up2 = unique_products.detect { |x| x[:product] ==  variant_3.product }

        expect(up1[:mid_code]).to eq supplier_2.mid_code
        expect(up1[:quantity]).to eq 4
        expect(up1[:total_price].to_f.round(2)).to eq 83.33
        expect(up1[:group]).to eq variant_2.product.product_group

        expect(up2[:mid_code]).to eq supplier_2.mid_code
        expect(up2[:quantity]).to eq 4
        expect(up2[:total_price].to_f.round(2)).to eq 16.67
        expect(up2[:group]).to eq variant_3.product.product_group
      end
    end

    context "digital part" do
      let(:digital_product) { create(:product, product_type: create(:product_type_gift_card)) }
      let!(:part2) do
        create(:line_item_part,
               optional: false,
               line_item: line_item_1,
               quantity: 2,
               variant: digital_product.master,
               price: 2.0,
               assembly_definition_part: adp2)
      end

      before do
        line_item_1.quantity.times do
          part2.quantity.times do
            create(:base_inventory_unit,
                   line_item: part2.line_item,
                   order: order,
                   variant: part2.variant,
                   supplier: supplier_2,
                   line_item_part: part2
                  )
          end
        end
      end

      it "ignores it" do
        unique_products = subject.result
        expect(unique_products.count).to eq 1
        up1 = unique_products.first
        expect(up1[:product]).to eq variant_2.product
      end
    end

    context "operational part" do
      let(:operational_product) { create(:product, product_type: create(:product_type_packaging)) }
      let!(:part2) do
        create(:line_item_part,
               optional: false,
               line_item: line_item_1,
               quantity: 2,
               variant: operational_product.master,
               price: 2.0,
               assembly_definition_part: adp2)
      end

      before do
        line_item_1.quantity.times do
          part2.quantity.times do
            create(:base_inventory_unit,
                   line_item: part2.line_item,
                   order: order,
                   variant: part2.variant,
                   supplier: supplier_2,
                   line_item_part: part2
                  )
          end
        end
      end

      it "ignores it" do
        unique_products = subject.result

        expect(unique_products.count).to eq 1
        up1 = unique_products.first
        expect(up1[:product]).to eq variant_2.product
      end
    end
  end
end
