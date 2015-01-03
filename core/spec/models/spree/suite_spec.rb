require 'spec_helper'

describe Spree::Suite do
  subject { create(:suite, name: ' Zion liOn haT  ', title: 'zion lion', permalink: nil) }

  describe '#title' do
    subject { super().title }
    it { is_expected.to eql('zion lion') }
  end

  it "should not allow unnamed group to be saved" do
    subject.name = nil
    expect(subject).to be_invalid
  end

  context "permalink" do
    describe '#permalink' do
      subject { super().permalink }
      it { is_expected.to eql('zion-lion-hat') }
    end

    it "can change permalink" do
      subject.permalink = 'anything-unique'
      expect(subject.save).to be true
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



  # TODO: touching
  # describe "touching" do
  #   let!(:index_page_item) { create(:index_page_item, suite: subject, updated_at: 1.month.ago) }

  #   before { Timecop.freeze }
  #   after { Timecop.return }

  #   it "touches any index page items after a touch" do
  #     subject.reload # reload to pick up the suite has_many
  #     subject.touch
  #     expect(index_page_item.reload.updated_at).to be_within(1.seconds).of(Time.now)
  #   end

  #   it "touches any index page items after a save" do
  #     subject.reload # reload to pick up the suite has_many
  #     subject.title = 'ffff'
  #     subject.save
  #     expect(index_page_item.reload.updated_at).to be_within(1.seconds).of(Time.now)
  #   end
  # end




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
