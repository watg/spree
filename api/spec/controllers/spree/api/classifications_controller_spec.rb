require 'spec_helper'

module Spree
  describe Api::ClassificationsController do
    let(:taxon) do
      taxon = create(:taxon)
      3.times do
        suite = create(:suite)
        suite.taxons << taxon
      end
      taxon
    end

    before do
      stub_authentication!
    end

    context "as a user" do
      it "cannot change the order of a suite" do
        api_put :update, :taxon_id => taxon, :suite_id => taxon.suites.first, :position => 1
        response.status.should == 401
      end
    end

    context "as an admin" do
      sign_in_as_admin!

      it "can change the order a suite" do
        last_suite = taxon.suites.last
        classification = taxon.classifications.find_by(:suite_id => last_suite.id)
        classification.position.should == 3
        api_put :update, :taxon_id => taxon, :suite_id => last_suite, :position => 0
        response.status.should == 200
        classification.reload.position.should == 1
      end
    end
  end
end