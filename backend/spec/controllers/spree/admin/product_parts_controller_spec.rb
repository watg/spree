require "spec_helper"

module Spree
  module Admin
    describe ProductPartsController do
      stub_authorization!
      render_views

      let!(:variant)       { create(:base_variant) }
      let!(:part_variant)  { create(:base_variant) }
      let(:product)       { variant.product }
      let(:part)          { part_variant.product }

      let!(:adp_opts) do
        {
          product: product,
          part: part,
          presentation: "Choose your weapon"
        }
      end

      describe "#index" do
        let!(:adp)     { create(:assembly_definition_part, adp_opts) }
        it "renders view successfully" do
          spree_get :index, product_id: product.slug
          expect(response.body).to include "Choose your weapon"
          expect(response.body).to include part.name
        end
      end

      describe "#create" do
        let(:params) do
          {
            "product_part" => {
              "part_id" => part.id,
              "count" => "1",
              "optional" => "true",
              "presentation" => "Nice trim"
            },
            "product_id" => product.slug
          }
        end

        it "renders view successfully" do
          spree_post :create, params
          expect(response).to be_redirect

          product_parts = product.product_parts
          expect(product_parts.size).to eq 1
          product_part = product_parts.first
          expect(product_part.optional).to eq true
          expect(product_part.count).to eq 1
          expect(product_part.presentation).to eq "Nice trim"
          expect(product_part.part).to eq part
          expect(product_part.product).to eq product
        end
      end

      describe "#update_all" do
        let!(:adp)     { create(:assembly_definition_part, adp_opts) }

        context "adding a variant" do
          let(:option_type) { create(:option_type) }
          let(:params) do
            {
              "product" => {
                "product_parts_attributes" => {
                  "0" => {
                    "position" => "2",
                    "presentation" => "Foo",
                    "displayable_option_type_id" => option_type.id,
                    "add_all_available_variants" => "1",
                    "variant_ids" => ["", part_variant.id],
                    "count" => "2",
                    "optional" => "0",
                    "id" => adp.id
                  }
                }
              },
              "product_id" => product.slug
            }
          end

          before do
            part.option_types << option_type
          end

          it "renders view successfully" do
            product_parts = product.product_parts
            spree_put :update_all, params
            expect(flash[:error]).to be_nil
            expect(response).to be_redirect

            product_parts = product.product_parts
            expect(product_parts.size).to eq 1
            product_part = product_parts.first
            expect(product_part.optional).to eq false
            expect(product_part.count).to eq 2
            expect(product_part.presentation).to eq "Foo"
            expect(product_part.add_all_available_variants).to eq true
            expect(product_part.displayable_option_type).to eq option_type
            expect(product_part.position).to eq 2
            expect(product_part.part).to eq part
            expect(product_part.product).to eq product
            expect(product_part.variants).to eq [part_variant]
          end
        end

        context "flash errors" do
          let!(:adp)     { create(:assembly_definition_part, adp_opts) }
          let(:params) do
            {
              "product" => {
                "product_parts_attributes" => {
                  "0" => {
                    "id" => adp.id,
                    "variant_ids" => ["", 22],
                  }
                }
              },
              "product_id" => product.slug
            }
          end

          it "creates errors" do
            spree_put :update_all, params
            expect(flash[:error]).to_not be_nil
          end
        end

        context "updating an image" do
          let(:product_parts_image) { create(:product_parts_image, product: product, target: nil) }
          let(:target) { create(:target) }
          let(:params) do
            {
              "product" => {
                "product_parts_images_attributes" => {
                  product_parts_image.id => {
                    "target_id" => target.id, "id" => product_parts_image.id
                  }
                }
              },
              "product_id" => product.slug
            }
          end

          it "updates the image params" do
            spree_put :update_all, params
            expect(flash[:error]).to be_nil
            expect(response).to be_redirect

            images = product.product_parts_images
            expect(images.size).to eq 1
            image = images.first
            expect(image.target).to eq target
          end
        end
      end
    end
  end
end
