#-*- coding: utf-8 -*-
require 'spec_helper'

describe Spree::ServiceTrait::Prices do
  let(:prices) { [
    create(:price, :currency => 'GBP', :amount => 12), 
    create(:price, :currency => 'USD', :amount => 13),  
    create(:price, :currency => 'EUR', :amount => 14),
    create(:price, :currency => 'GBP', :amount => 2, :sale => true), 
    create(:price, :currency => 'USD', :amount => 3, :sale => true),  
    create(:price, :currency => 'EUR', :amount => 4, :sale => true),
    create(:price, :currency => 'GBP', :amount => 1, :is_kit => true), 
    create(:price, :currency => 'USD', :amount => 1, :is_kit => true),
    create(:price, :currency => 'EUR', :amount => 1, :is_kit => true),
  ] }
  let(:product) { FactoryGirl.create(:product) }
  let(:variant) { FactoryGirl.create(:base_variant, product_id: product.id, prices: prices) }

  let(:new_prices) { {
    :normal=>{"GBP"=>"£39.00", "USD"=>"$49.00", "EUR"=>"€47.00"}, 
    :normal_sale=>{"GBP"=>"£111.00", "USD"=>"$12.00", "EUR"=>"€0.00"}, 
    :part=>{"GBP"=>"£22.00", "USD"=>"$0.00", "EUR"=>"€0.00"}
  } }


  let(:dummy_class) {  OpenStruct.new.extend(Spree::ServiceTrait::Prices) }

  describe "#update_prices" do

    it "sets the prices on a variant" do

      dummy_class.update_prices(new_prices,variant) 
      variant.prices.size.should == 9
      variant.price_for_type(:normal, 'GBP').amount.should == 39.00
      variant.price_for_type(:normal, 'USD').amount.should == 49.00
      variant.price_for_type(:normal, 'EUR').amount.should == 47.00

      variant.price_for_type(:normal_sale, 'GBP').amount.should == 111.00
      variant.price_for_type(:normal_sale, 'USD').amount.should == 12.00
      variant.price_for_type(:normal_sale, 'EUR').amount.should == 0.00

      variant.price_for_type(:part, 'GBP').amount.should == 22.00
      variant.price_for_type(:part, 'USD').amount.should == 0.00
      variant.price_for_type(:part, 'EUR').amount.should == 0.00
    end

  end

  describe "#validate_prices" do

    it "accepts valid prices" do
      dummy_class.should_not_receive(:add_error)
      dummy_class.validate_prices(new_prices) 
    end

    it "does not accept missing currencies for normal" do
      dummy_class.should_receive(:add_error).with(:variant, :price, "price not set for type: normal, currency: GBP")
      new_prices[:normal].delete 'GBP'
      dummy_class.validate_prices(new_prices) 
    end

    it "does accept missing currencies for other price types" do
      dummy_class.should_not_receive(:add_error)
      new_prices[:normal_sale].delete 'GBP'
      dummy_class.validate_prices(new_prices) 
    end

    it "does not accept 0 amount for normal price" do
      dummy_class.should_receive(:add_error).with(:variant, :price, "amount can not be <= 0 for currency: GBP and normal price")
      new_prices[:normal]['GBP'] = '£0'
      dummy_class.validate_prices(new_prices) 
    end

  end
end
