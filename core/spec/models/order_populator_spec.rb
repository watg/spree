require 'spec_helper'

describe Spree::OrderPopulator do
  describe "Class Method" do
    let(:assembly_definition_parts) { [double(id: 23, count: 3, optional: false)] }
    let(:selected_variant) { create(:variant) }
    let(:kit) { create(:variant) }
    subject { Spree::OrderPopulator }
    before do
      allow(kit.product).to receive(:assembly_definitions).and_return(assembly_definition_parts)
    end
    it "returns a list of selected variants with defined quantity" do
      actual = subject.parse_options(kit, {23 =>  selected_variant.id} )
      expect(actual).to match_array([[selected_variant, 3, false]])
    end
  end
end
