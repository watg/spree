require 'spec_helper'

describe Spree::CreateProductPageVariantsService do
  subject { Spree::CreateProductPageVariantsService }
  let(:existing_variants) { create_list(:variant, 2) }
  let(:new_variant) { create(:variant) }
  let(:product_page) { create(:product_page) }

  before :each do
    existing_variants.each_with_index do |variant, pos|
      create(:product_page_variant, product_page: product_page, variant: variant, position: pos)
    end
  end

  it "adds the variant to the product page" do
    subject.run(product_page: product_page, variant_id: new_variant.id)
    expect(product_page.reload.displayed_variants).to match_array(existing_variants << new_variant)
  end

  it "target information is stored in joining table" do
    subject.run(product_page: product_page, variant_id: new_variant.id)
    expect(product_page.reload.product_page_variants.last.target).to eq(product_page.target)
  end

  it "sets the position to the end of the list, based on type" do
    subject.run(product_page: product_page, variant_id: new_variant.id)
    product_page_variant = product_page.reload.product_page_variants.where(variant_id: new_variant.id).first
    expect(product_page_variant.position).to eq(2)
  end

  context "when there are no existing variants" do
    before :each do
      product_page.product_page_variants = []
    end

    it "sets the position to 1" do
    subject.run(product_page: product_page, variant_id: new_variant.id)
    product_page_variant = product_page.reload.product_page_variants.first
    expect(product_page_variant.position).to eq(1)
    end
  end

  context "without a target" do
    before do
      product_page.update_attributes(target: nil)
    end

    it "adds the variant to the product page" do
      subject.run(product_page: product_page, variant_id: new_variant.id)
      expect(product_page.reload.displayed_variants).to match_array(existing_variants << new_variant)
    end
  end
end
