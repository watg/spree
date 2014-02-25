## encoding: utf-8

require 'spec_helper'

describe Spree::LineItemPersonalisation do
  let(:monogram) { create(:personalisation_monogram) }
  let(:lip) { build(:line_item_personalisation) }

  context "#generate_uuid" do
    let(:personalisation_params) {[{
      personalisation_id: monogram.id,
      amount: 123,
      data: { 'colour' => monogram.colours.first.id, 'initials' => 'DD'},
    }]}
    subject { Spree::LineItemPersonalisation.generate_uuid personalisation_params }

    it "returns textual description of the personalisation" do
      subject.should == "#{monogram.id}-colour-#{monogram.colours.first.id}-initials-DD"
    end
  end

  context "#name" do
    subject { lip.name }

    it "returns name of the personalisation" do
      subject.should == 'monogram'
    end
  end

  context "#text" do
    subject { lip.name }

    it "returns textual description of the personalisation" do
      subject.should == 'monogram' 
    end
  end

  context "#data_to_text" do
    subject { lip.data_to_text }

    it "returns textual description of the personalisation" do
      subject.should == 'Colour: Red, Initials: DD'
    end
  end

  context "#personalisation" do
    let(:lip2) { create(:line_item_personalisation,:personalisation => monogram ) }
    subject { lip2.personalisation }

    it "returns the personalisation " do
      lip2.reload
      subject.should == monogram 
    end

    context "when persoanlisation is deleted" do
      before do
        monogram.destroy
      end

      it "returns the personalisation " do
        lip2.reload
        subject.should == monogram 
      end
    end
  end

end



