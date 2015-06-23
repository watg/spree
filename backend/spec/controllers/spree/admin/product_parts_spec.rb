require "spec_helper"

module Spree
  module Admin
    describe ProductPartsController do
      stub_authorization!
      render_views

      describe "#edit" do
        let(:product)  { create(:product) }
        let(:part)     { create(:product) }
        let!(:adp)     { create(:assembly_definition_part, adp_opts) }
        let(:adp_opts) do
          {
            product: product,
            part: part,
            presentation: "Choose your weapon"
          }
        end

        it "renders view successfully" do
          spree_get :index, product_id: product.slug
          expect(response.body).to include "Choose your weapon"
          expect(response.body).to include part.name
        end
      end
    end
  end
end
