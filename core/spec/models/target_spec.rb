require 'spec_helper'

describe Spree::Target do
  describe ".not_in" do
    let(:used_targets) { create_list(:target, 2) }
    let(:unused_targets) { create_list(:target, 2) }
    # let(:variant) { create(:variant, targets: used_targets) }
    subject { Spree::Target }

    it "returns the targets which aren't associated with an object" do
      variant = create(:variant)
      variant.targets = used_targets
      expect(subject.not_in(variant)).to match_array(unused_targets)
    end
  end
end
