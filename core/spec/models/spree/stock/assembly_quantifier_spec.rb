require 'spec_helper'

describe Spree::Stock::AssemblyQuantifier do
  let(:kit) { create(:product, product_type: :kit) }
  let(:variants) { create_list(:variant_with_stock_items, 4) }

  before do
    kit.add_part(variants.first, 1, true)
    kit.add_part(variants[1], 5)

    variants[2].add_part(variants[3], 7)
    kit.variants << variants[2]
    kit.save
  end
  
  context "#can_supply?" do
    subject { Spree::Stock::AssemblyQuantifier.new(kit.variants.first) }

    it "returns true when all required parts are in stock" do
      expect(subject.can_supply?(1)).to be_true
    end

    it "returns false when at least no of the required parts is out of stock" do
      expect(subject.can_supply?(2)).to be_false
    end
  end
end
