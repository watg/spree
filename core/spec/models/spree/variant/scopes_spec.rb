require 'spec_helper'

describe "Variant scopes", :type => :model do
  let!(:product) { create(:product) }
  let!(:variant_1) { create(:variant, :product => product) }
  let!(:variant_2) { create(:variant, :product => product) }

  it ".descend_by_popularity" do
    # Requires a product with at least two variants, where one has a higher number of
    # orders than the other
    Spree::LineItem.delete_all # FIXME leaky database - too many line_items
    create(:line_item, :variant => variant_1)
    expect(Spree::Variant.descend_by_popularity.first).to eq(variant_1)
  end

  context "finding by option values" do
    let!(:option_type) { create(:option_type, :name => "bar") }
    let!(:option_value_1) do
      option_value = create(:option_value, :name => "foo", :presentation => 'Foo', :option_type => option_type)
      variant_1.option_values << option_value
      option_value
    end

    let!(:option_value_2) do
      option_value = create(:option_value, :name => "fizz", :presentation => 'Fizz', :option_type => option_type)
      variant_1.option_values << option_value
      option_value
    end

    let!(:product_variants) { product.variants_including_master }

    it "by objects" do
      variants = product_variants.has_option(option_type, option_value_1)
      expect(variants).to include(variant_1)
      expect(variants).not_to include(variant_2)
    end

    it "by names" do
      variants = product_variants.has_option("bar", "foo")
      expect(variants).to include(variant_1)
      expect(variants).not_to include(variant_2)
    end

    it "by ids" do
      variants = product_variants.has_option(option_type.id, option_value_1.id)
      expect(variants).to include(variant_1)
      expect(variants).not_to include(variant_2)
    end

    it "by mixed conditions" do
      variants = product_variants.has_option(option_type.id, "foo", option_value_2)
    end
  end
end
