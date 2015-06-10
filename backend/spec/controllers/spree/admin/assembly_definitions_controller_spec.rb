require "spec_helper"

module Spree
  module Admin
    describe AssemblyDefinitionsController do
      stub_authorization!
      render_views

      describe "#edit" do
        let(:ad)       { create(:assembly_definition) }
        let!(:adp)     { create(:assembly_definition_part, adp_opts) }
        let(:adp_opts) { { assembly_definition: ad, presentation: "Choose your weapon"} }

        it "renders view successfully" do
          spree_get :edit, id: ad.id
          expect(response.body).to include "Choose your weapon"
        end
      end
    end
  end
end
