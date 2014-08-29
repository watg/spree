require 'spec_helper'

describe Spree::PackingListService do

  subject { Spree::PackingListService.run(order: order) }

  let(:order) { create(:order) }
  let(:usa) { create(:country)}
  let(:variant) { create(:base_variant) }
  let(:supplier) { create(:supplier) }
  let(:line_item_1) { create(:line_item, order: order, variant: variant) }

  it "returns a header" do
    result = subject.result
    header = result.first
    expect(header).to eq Spree::PackingListService::HEADER
  end

  context "Normal product" do

    let!(:inventory_unit_1) { create(:base_inventory_unit, line_item: line_item_1, order: order, variant: variant, supplier: supplier) }

    it "returns the correct data" do
      result = subject.result
      expect(result.size).to eq 2
      data = result.second
      expect(data).to eq [
        variant.product.name,
        "#{variant.sku} \n [#{supplier.permalink}]", 
        "",
        variant.options_text,
        1,
        "|_|"
      ]
    end


    context "Inventory units have different suppliers" do

      let(:line_item_1) { create(:line_item, order: order, variant: variant, quantity: 2) }
      let(:supplier_2) { create(:supplier) }
      let!(:inventory_unit_2) { create(:base_inventory_unit, line_item: line_item_1, order: order, variant: variant, supplier: supplier_2) }

      it "returns the correct data" do
        result = subject.result
        expect(result.size).to eq 3
        expect(result).to match_array([
          Spree::PackingListService::HEADER,
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
          ]]
        )

      end

    end

  end

  context "Assmebly" do

    let(:line_item_1) { create(:line_item, variant: variant, order: order, quantity: 2) }
    let(:variant_2) { create(:variant) }
    let(:supplier_2) { create(:supplier) }
    let!(:part1) { create(:line_item_part, optional: false, line_item: line_item_1, quantity: 2, variant: variant_2, price: 8.0) }

    before do
      line_item_1.quantity.times do
        part1.quantity.times do
          create(:base_inventory_unit, line_item: part1.line_item, order: order, variant: part1.variant, supplier: supplier_2)
        end
      end
    end

    it "returns the correct data" do
      result = subject.result
      expect(result).to match_array([
        Spree::PackingListService::HEADER,
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
        ]]
       )
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
        expect(result).to match_array([
          Spree::PackingListService::HEADER,
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
          ]]
        )
      end


    end

  end

  context "Personalisation" do

    let!(:lip) { create(:line_item_personalisation, line_item: line_item_1 ) }

    it "returns the correct data" do
      result = subject.result
      expect(result.size).to eq 2
      expect(result).to match_array([
        Spree::PackingListService::HEADER,
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


