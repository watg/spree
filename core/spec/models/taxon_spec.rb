require 'spec_helper'

describe Spree::Taxon do
  let(:parent_taxon){ FactoryGirl.create(:taxon, name: "Women")}
  let(:subject)     { FactoryGirl.create(:taxon, name: "Sweaters & Jumpers", parent_id: parent_taxon.id) }
  its(:pretty_name) { should eq("Women -> Sweaters & Jumpers") }

  describe "displayable" do
    let!(:hidden_taxon) { create(:taxon, hidden: true, name: 'hidden')}
    let!(:non_hidden_taxon) { create(:taxon, hidden: false, name: 'non_hidden')}

    it "removes hidden taxons" do
      expect(described_class.where(name: 'hidden').displayable).to match_array []
    end

    it "returns non hidden taxons" do
      expect(described_class.where(name: 'non_hidden').displayable).to match_array [non_hidden_taxon]
    end

  end

end
