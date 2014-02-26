require 'spec_helper'

describe Spree::Stock::Quantifier do
  subject { Spree::Stock::Quantifier }
  let(:kit) { create(:product, product_type: :kit) }
  let(:made_by_the_gang) { create(:product, product_type: :made_by_the_gang) }

  it "returns Simple Quantifier for non-assembly variants" do
    expect(subject.new(made_by_the_gang.master)).to be_kind_of(Spree::Stock::SimpleQuantifier)
  end

  it "returns Assembly Quantifier for kits and assembly variants" do
    expect(subject.new(kit.master)).to be_kind_of(Spree::Stock::AssemblyQuantifier)
  end

end
