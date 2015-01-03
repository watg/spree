require 'spec_helper'

describe Spree::Personalisation do
  let(:pm) { build(:personalisation_monogram) }

  context "#selected_data_to_text" do
    let(:selected_data) {{
      'colour' => pm.colours.first.id,
      'initials' => 'DD'
    }}
    subject { pm.selected_data_to_text selected_data }

    it "returns textual description of the personalisation" do
      expect(subject).to eq('Colour: Red, Initials: DD')
    end
  end

  context "#options_to_text" do
    subject { pm.options_text }
    it "returns textual description of the personalisation" do
      expect(subject).to eq("Colours: Red\n Max Initials: 2")
    end
  end

  context "#colours" do
    subject { pm.colours }
    it "returns textual description of the personalisation" do
      expect(subject.map(&:presentation)).to eq(["Red"])
    end
  end

  context "#max_initials" do
    subject { pm.max_initials }
    it "returns textual description of the personalisation" do
      expect(subject).to eq(2)
    end
  end

end
