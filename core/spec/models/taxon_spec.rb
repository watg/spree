require 'spec_helper'

describe Spree::Taxon do
  let(:parent_taxon){ FactoryGirl.create(:taxon, name: "Women")}
  let(:subject)     { FactoryGirl.create(:taxon, name: "Sweaters & Jumpers", parent_id: parent_taxon.id) }
  its(:pretty_name) { should eq("Women -> Sweaters & Jumpers") }
end
