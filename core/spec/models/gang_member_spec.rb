require 'spec_helper'

describe Spree::GangMember do

  its(:products) { should be_kind_of(ActiveRecord::Associations::CollectionProxy) }

  it "generates permalinks" do
    gang_member1 = create(:gang_member, firstname: "Queen", lastname: "Knitter 1", permalink: nil)
    gang_member2 = create(:gang_member, firstname: "Queen", lastname: "Knitter 2", permalink: nil)
    gang_member3 = create(:gang_member, firstname: "Queen Marry", lastname: "Knitter 3", permalink: nil)

    expect(gang_member1.permalink).to eq "queen-1"
    expect(gang_member2.permalink).to eq "queen-2"
    expect(gang_member3.permalink).to eq "queen-marry-1"
  end
end
