require 'spec_helper'

describe Spree::Suite do
  subject { create(:suite, name: ' Zion liOn haT  ', title: 'zion lion', permalink: nil) }

  its(:title) { should eql('zion lion') }

  it "should not allow unnamed group to be saved" do
    subject.name = nil
    expect(subject).to be_invalid
  end

  context "permalink" do
    its(:permalink) { should eql('zion-lion-hat') }

    it "can change permalink" do
      subject.permalink = 'anything-unique'
      expect(subject.save).to be_true
    end

    it "does not include illegal charecters" do
      suite = create(:suite, permalink: "wacky,' day")
      expect(suite.permalink).to eq "wacky-day"
    end
  end

  context "validation" do
    it "name is unique" do
      same_name_pg = build(:suite, name: subject.name)
      expect(same_name_pg).to be_invalid
    end

    it "title is required" do
      suite = build(:suite)
      expect(suite).to be_valid
      suite.title = ""
      expect(suite).to be_invalid
    end
  end


  # Regression tests for #2352
  context "classifications and taxons" do
    it "is joined through classifications" do
      reflection = Spree::Suite.reflect_on_association(:taxons)
      expect(reflection.options[:through]).to eq(:classifications)
    end

    it "will delete all classifications" do
      reflection = Spree::Suite.reflect_on_association(:classifications)
      expect(reflection.options[:dependent]).to eq(:destroy)
    end
  end
end
