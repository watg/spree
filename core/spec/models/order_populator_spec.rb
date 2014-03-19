require 'spec_helper'

describe Spree::OrderPopulator do
  describe "Class Method" do
    let(:assembly_definition_parts) { [double(id: 23, count: 3, optional: false)] }
    let(:assembly_definition) { double(parts: assembly_definition_parts) }
    let(:selected_variant) { create(:variant) }
    let(:kit) { create(:variant) }
    subject { Spree::OrderPopulator }
    before do
      allow_any_instance_of(Spree::Product).to receive(:assembly_definition).and_return(assembly_definition)
    end
    it "returns a list of selected variants with defined quantity" do
      actual = subject.parse_options(kit, {23 =>  selected_variant.id} )
      expect(actual).to match_array([[selected_variant, 3, false, 23]])
    end
  end
end
