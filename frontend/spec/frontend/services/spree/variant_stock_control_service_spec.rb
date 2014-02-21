require 'spec_helper'

describe Spree::VariantStockControlService do
  subject { Spree::VariantStockControlService }

  let(:product)               { create(:product_with_variants_displayable) }
  let(:variant_in_stock)      { create(:base_variant, product_id: product.id) }
  let(:variants_out_of_stock) { create_list(:base_variant, 3, product_id: product.id) }
  let(:variant_out_of_stock)  { variants_out_of_stock.last }
  
  it "does nothing when variant is in stock" do
    allow(variant_in_stock).to receive(:out_of_stock?) { false }
    outcome = subject.run(selected_variant: variant_in_stock)
    expect(outcome.result).to eq({redirect_to: nil})
  end

  context "when a kit or virtual product" do
    before do
      allow(variant_out_of_stock).to receive(:out_of_stock?) { true }
      allow(variant_out_of_stock).to receive(:kit?) { true }
    end

    it "returns a redirect of nil" do
      outcome = subject.run(selected_variant: variant_out_of_stock)
      expect(outcome.result).to eq({redirect_to: nil})
    end

  end

  context "selected variant out of stock" do
    before do
      allow(variant_out_of_stock).to receive(:out_of_stock?) { true }
      allow(variant_out_of_stock.product).to receive(:next_variant_in_stock) { variant_in_stock }
      allow(variant_out_of_stock.product.product_group).to receive(:next_variant_in_stock) { variant_in_stock }
    end

    it "returns the first variant in stock in product or product_group" do
      path = "/shop/products/#{variant_in_stock.product.permalink}/#{option_values(variant_in_stock)}"
      msg = "The <b>#{variant_out_of_stock.product.name} #{variant_out_of_stock.options_text}</b> has been snapped up.<br/> Luckily we have another <b>#{variant_in_stock.product.name} #{variant_in_stock.options_text}</b> knitted  by the Gang." 

      outcome = subject.run(selected_variant: variant_out_of_stock)
      expect(outcome.result).to eq({redirect_to: path, message: msg})
    end

    it "returns section index when no variants in stock" do
      allow(variant_out_of_stock.product).to receive(:next_variant_in_stock).with(variant_out_of_stock) { nil }
      
      path = "/shop/products/#{variant_in_stock.product.permalink}/#{option_values(variant_in_stock)}"
      msg = "The <b>#{variant_out_of_stock.product.name} #{variant_out_of_stock.options_text}</b> has been snapped up.<br/> Luckily we have another <b>#{variant_in_stock.product.name} #{variant_in_stock.options_text}</b> knitted  by the Gang." 

      outcome = subject.run(selected_variant: variant_out_of_stock)
      expect(outcome.result).to eq({redirect_to: path, message: msg})
    end


    it "returns section index when no variants in stock" do
      allow(variant_out_of_stock.product).to receive(:next_variant_in_stock) { nil }
      allow(variant_out_of_stock.product.product_group).to receive(:next_variant_in_stock) { nil }

      msg = "Sorry! The <b>#{variant_out_of_stock.product.name} #{variant_out_of_stock.options_text}</b> has sold out. Check out our other knits made unique by the Gang." 

      outcome = subject.run(selected_variant: variant_out_of_stock)
      expect(outcome.result).to eq({redirect_to: '/shop/t/tops-and-hats', message: msg})
    end


  end


  def option_values(variant)
    variant.option_values.order('option_type_id ASC').map { |ov| ov.name }.join('/')
  end
end
