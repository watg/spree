require 'spec_helper'

describe Spree::VariantUuid do
  let(:variant) { create(:variant) }
  let(:options_required) {[
                           [variant, 4, false, 1],
                           [variant, 1, false, 2]
                          ]}
  let(:options) { options_required << [variant, 1] }
  let(:personalisations) { [] }
  
  subject { Spree::VariantUuid.fetch(variant, options, personalisations) }

  before do
    allow(Spree::AssemblyDefinitionPart).to receive(:find).and_return(double)

  end

  describe "::fetch" do
    subject { Spree::VariantUuid }
    let(:vuuid) { double("VariantUuid")}
    let!(:existing_vuuid) { Spree::VariantUuid.create(recipe_sha1: "pick-me") }

    it "create a variant uuid the first it is asked for" do
      expect(Spree::VariantUuid).to receive(:create).and_return(vuuid)
      subject.fetch(variant)
    end

    it "retrieves a variant uuid the subsequent time it is asked for" do
      allow(Digest::SHA1).to receive(:hexdigest).and_return("pick-me")
      expect(subject.fetch(variant)).to eq existing_vuuid
    end

    it "uses submitted params to identify variant uuid" do
      hsh = subject.send(:build_hash, variant, options, personalisations)
      expected_hsh = {
        base_variant_id: variant.id,
        options: [{part_id: 1, quantity: 4, variant_id: variant.id},
                  {part_id: 2, quantity: 1, variant_id: variant.id},
                  {part_id: nil, quantity: 1, variant_id: variant.id}],
        personalisations: personalisations
      }
      expect(hsh).to eq expected_hsh
    end
  end

  its(:base_variant)     { should eq variant }
  its(:options)          { should_not be_blank }
  its(:personalisations) { should eq personalisations }
  its(:number)           { should_not be_blank }
end
