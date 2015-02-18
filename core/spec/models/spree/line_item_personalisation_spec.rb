## encoding: utf-8

require 'spec_helper'

describe Spree::LineItemPersonalisation do
  let(:monogram) { create(:personalisation_monogram) }
  let(:lip) { build(:line_item_personalisation) }

  context "#name" do
    subject { lip.name }

    it "returns name of the personalisation" do
      expect(subject).to eq('monogram')
    end
  end

  context "#text" do
    subject { lip.name }

    it "returns textual description of the personalisation" do
      expect(subject).to eq('monogram') 
    end
  end

  context "#data_to_text" do
    subject { lip.data_to_text }

    it "returns textual description of the personalisation" do
      expect(subject).to eq('Colour: Red, Initials: DD')
    end
  end

  context "#personalisation" do
    let(:lip2) { create(:line_item_personalisation,:personalisation => monogram ) }
    subject { lip2.personalisation }

    it "returns the personalisation " do
      lip2.reload
      expect(subject).to eq(monogram) 
    end

    context "when persoanlisation is deleted" do
      before do
        monogram.destroy
      end

      it "returns the personalisation " do
        lip2.reload
        expect(subject).to eq(monogram) 
      end
    end
  end

end



