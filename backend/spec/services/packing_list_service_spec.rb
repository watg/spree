require 'spec_helper'

describe Spree::PackingListService do

  subject { Spree::PackingListService.run(order: order) }

  let(:order) { Spree::Order.new }
  let(:usa) { create(:country)}
  let(:variant) { create(:base_variant) }
  let(:supplier) { create(:supplier) }
  let(:line_item_1) { build(:line_item, order: order, variant: variant) }

  before do
    order.line_items << line_item_1
  end

  it "returns a header" do
    result = subject.result
    header = result.header
    expect(header).to eq Spree::PackingListService::HEADER
  end

  context "Normal product" do

    let!(:inventory_unit_1) { create(:base_inventory_unit, line_item: line_item_1, order: order, variant: variant, supplier: supplier) }

    it "returns the correct data" do
      result = subject.result
      body = result.body
      expect(body).to eq [[
        variant.product.name,
        "#{variant.sku} \n [#{supplier.permalink}]",
        "",
        variant.options_text,
        1,
        "|_|"
      ]]
    end

    context "when supplier is not a company" do
      before do
        supplier.update_column(:is_company, true)
      end

      it "does not show supplier permalink " do
        result = subject.result
        body = result.body
        expect(body).to eq [[
          variant.product.name,
          "#{variant.sku}",
          "",
          variant.options_text,
          1,
          "|_|"
        ]]
      end
    end

    context "Inventory units have different suppliers" do

      let(:line_item_1) { create(:line_item, order: order, variant: variant, quantity: 2) }
      let(:supplier_2) { create(:supplier) }
      let!(:inventory_unit_2) { create(:base_inventory_unit, line_item: line_item_1, order: order, variant: variant, supplier: supplier_2) }

      it "returns the correct data" do
        result = subject.result
        expect(result.body.size).to eq 2
        expect(result.body).to match_array([
          [
            variant.product.name,
            "#{variant.sku} \n [#{supplier.permalink}]",
            "",
            variant.options_text,
            1,
            "|_|"
          ],
          [
            variant.product.name,
            "#{variant.sku} \n [#{supplier_2.permalink}]",
            "",
            variant.options_text,
            1,
            "|_|"
          ]
        ])

      end

    end

  end

  context "Assmebly" do

    let(:line_item_1) { build(:line_item, variant: variant, order: order, quantity: 2) }
    let(:variant_2) { create(:variant) }
    let(:supplier_2) { create(:supplier) }
    let(:part1) { create(:line_item_part, optional: false, line_item: line_item_1, quantity: 2, variant: variant_2, price: 8.0) }

    before do
      line_item_1.parts << part1
      line_item_1.quantity.times do
        part1.quantity.times do
          create(:base_inventory_unit, line_item: part1.line_item, order: order, variant: part1.variant, supplier: supplier_2)
        end
      end
    end

    it "returns the correct data" do
      result = subject.result
      expect(result.body).to match_array([
        [
          "KIT - #{variant.product.name}",
          "#{variant.sku}",
          "",
          variant.options_text,
          2,
          "|_|"
        ],
        [
          "",
          "#{variant_2.sku} \n [#{supplier_2.permalink}]",
          variant_2.product.name,
          variant_2.options_text,
          4,
          "|_|"
        ]
      ])
    end

    context "with containers and assembled parts" do
      let!(:container_part) { create(:line_item_part, line_item: line_item_1, quantity: 5, variant: variant, container: true, assembled: true) }

      before do
        part1.assembled = true
        part1.main_part = true
        part1.save!
        line_item_1.parts << container_part
      end

      it "includes any part containers and uses a CUSTOM prefix" do
        result = subject.result
        expect(result.body).to match_array([
          [
            "CUSTOM - #{variant.product.name}",
            "#{variant.sku}",
            "",
            variant.options_text,
            2,
            "|_|"
          ],
          [
            "",
            "#{variant_2.sku} \n [#{supplier_2.permalink}]\n Customize No: <b>#{part1.id}</b>",
            variant_2.product.name,
            variant_2.options_text,
            4,
            "|_|"
          ],
          [
            "",
            variant.sku,
            variant.product.name,
            variant.options_text,
            5,
            "|_|"
          ]
        ])
      end
    end


    context "Inventory units have different suppliers" do

      let(:supplier_3) { create(:supplier) }

      before do
        iu = line_item_1.inventory_units.detect { |iu| iu.variant == part1.variant }
        iu.supplier = supplier_3
        iu.save
      end

      it "returns the correct data" do
        result = subject.result
        expect(result.body).to match_array([
          [
            "KIT - #{variant.product.name}",
            "#{variant.sku}",
            "",
            variant.options_text,
            2,
            "|_|"
          ],
          [
            "",
            "#{variant_2.sku} \n [#{supplier_2.permalink}]",
            variant_2.product.name,
            variant_2.options_text,
            3,
            "|_|"
          ],
          [
            "",
            "#{variant_2.sku} \n [#{supplier_3.permalink}]",
            variant_2.product.name,
            variant_2.options_text,
            1,
            "|_|"
          ]
        ])
      end
    end

    context "Contains parts with parent part ID" do

      before do
        part1.parent_part_id = 21
        part1.save!
      end

      it "skips parts with parent part ID" do
        result = subject.result
        expect(result.body).to match_array([
          [
            "KIT - #{variant.product.name}",
            "#{variant.sku}",
            "",
            variant.options_text,
            2,
            "|_|"
          ]
        ])
      end
    end

  end

  context "Personalisation" do

    let!(:lip) { create(:line_item_personalisation, line_item: line_item_1 ) }

    it "returns the correct data" do
      result = subject.result
      expect(result.body).to match_array([
        [
          "",
          "",
          "monogram",
          "Colour: Red, Initials: DD",
          "",
          "|_|"
        ],
      ])
    end
  end

end


