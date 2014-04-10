require 'spec_helper'

describe Spree::PinterestService do
  
  it "returns a correct OpenStruct response with a product" do
    product = FactoryGirl.create(:product_with_variants_displayable)
    variant = product.variants.first
    variant_slug = variant.option_values.first.name
    variant.in_stock_cache = true
    variant.save
    url = "http://www.woolandthegang.com/shop/products/#{product.slug}/#{variant_slug}"
    
    outcome = Spree::PinterestService.run({url: url})
    
    outcome.success?.should == true
    outcome.result.product_id.should == product.slug
    outcome.result.title.should == product.name.to_s + " #madeunique by The Gang"
    
    outcome.result.price.should == variant.current_price_in("GBP").amount
    outcome.result.currency_code.should == "GBP"
    outcome.result.availability.should == "in stock"
  end

  it "returns a could_not_parse_url error" do
    url = "invalid_string"
    outcome = Spree::PinterestService.run({url: url})
    outcome.errors.symbolic[:url].should == :could_not_parse_url
  end

  it "returns a could_not_find_product error" do
    url = "http://www.woolandthegang.com/shop/products/invalid_product/variant_slug"
    outcome = Spree::PinterestService.run({url: url})
    outcome.errors.symbolic[:url].should == :could_not_find_product
  end

end
