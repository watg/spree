require 'spec_helper'

describe Spree::Admin::ShippingManifestsController, type: :controller do
  stub_admin_user
  context "#index" do
    it "should find available manifests" do
      expect(Metapack::Client).to receive(:find_ready_to_manifest_records).and_return(:manifests)
      spree_get :index
      expect(assigns[:manifests]).to eq(:manifests)
    end
  end

  context "#create" do
    before :each do
      allow(Metapack::Client).to receive(:create_manifest).and_return(:pdf)
    end


    it "creates the manifest" do
      expect(Metapack::Client).to receive(:create_manifest).with("DHL")
      spree_post :create, :carrier => "DHL"
    end

    it "responds with the PDF" do
      spree_post :create, :carrier => "DHL"
      expect(response.body).to eq("pdf")
      expect(response.headers["Content-Type"]).to eq("application/pdf")
      expect(response.headers["Content-Disposition"]).to eq("inline; filename=\"DHL-manifest.pdf\"")
    end
  end
end
