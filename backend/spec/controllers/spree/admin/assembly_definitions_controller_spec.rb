require "spec_helper"

module Spree
  module Admin
    describe AssemblyDefinitionsController do
      stub_authorization!
      render_views

      describe "#edit" do
        let(:ad)       { create(:assembly_definition) }
        let(:product)  { create(:product) }
        let(:part)     { create(:product) }
        let!(:adp)     { create(:assembly_definition_part, adp_opts) }
        let(:adp_opts) do
          {
            assembly_definition: ad,
            assembly_product_id: product.id,
            part: part,
            presentation: "Choose your weapon"
          }
        end

        it "renders view successfully" do
          spree_get :edit, id: ad.id
          expect(response.body).to include "Choose your weapon"
          expect(response.body).to include part.name
        end
      end
    end
  end
end
