require 'spec_helper'

describe Spree::IndexPage do

  describe "permalink" do
    subject { create(:index_page, name: "Fever pitch", permalink: nil) }

    its(:permalink) { should eql('fever-pitch') }

    it "raises validation error with illegal charecters" do
      index_page = build(:index_page, permalink: "wacky,' day")
      expect(index_page).to be_invalid
    end

    it "sets permalink with letters, -, _, and numbers" do
      index_page = build(:index_page, permalink: "123abc-_tonight")
      expect(index_page).to be_valid
    end
  end

  describe "touching" do
    let(:taxonomy) { create(:taxonomy, updated_at: 1.day.ago) }
    let(:taxon) { create(:taxon, taxonomy: taxonomy, updated_at: 1.day.ago) }
    subject { create(:index_page, :taxon => taxon) }

    before { Timecop.freeze }
    after { Timecop.return }

    it "updates the taxon and taxonomy" do
      subject.touch
      expect(taxon.reload.updated_at).to be_within(1.second).of(Time.now)
      expect(taxonomy.reload.updated_at).to be_within(1.second).of(Time.now)
    end
  end
end
