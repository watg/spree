require 'spec_helper'

describe Spree::Admin::PersonalisationsHelper do
  include ActionView::Helpers::FormOptionsHelper
  include Spree::Admin::PersonalisationsHelper

  context "#options_for_product_personalisation_types" do
    let(:personalisation) { create(:personalisation_monogram)}
    let(:product1) { create(:product)}
    let(:product2) { create(:product, personalisations: [personalisation])}

    it "should return available personalisations" do
      options_for_product_personalisation_types(product1).should == "<option value=\"Spree::Personalisation::Monogram\">Monogram</option>\n<option value=\"Spree::Personalisation::Dob\">Dob</option>"
    end

    it "should return available when product already has a personalisation" do
      options_for_product_personalisation_types(product2).should == "<option value=\"Spree::Personalisation::Dob\">Dob</option>"
    end

  end

end
