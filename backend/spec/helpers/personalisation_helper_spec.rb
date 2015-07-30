require "spec_helper"

describe Spree::Admin::PersonalisationsHelper do
  include ActionView::Helpers::FormOptionsHelper
  include described_class

  context "#options_for_product_personalisation_types" do
    let(:personalisation) { create(:personalisation_monogram) }
    let(:product1) { create(:product) }
    let(:product2) { create(:product, personalisations: [personalisation]) }

    it "returns available personalisations" do
      expect(options_for_product_personalisation_types(product1)).to eq("<option value=\"Spree::Personalisation::Monogram\">Monogram</option>\n<option value=\"Spree::Personalisation::Dob\">Dob</option>")
    end

    it "returns available when product already has a personalisation" do
      expect(options_for_product_personalisation_types(product2)).to eq("<option value=\"Spree::Personalisation::Dob\">Dob</option>")
    end
  end
end
