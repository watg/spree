require 'spec_helper'

describe Spree::Admin::PrintJobsController, type: :controller do
  stub_authorization!

  describe "#index" do
    let!(:print_jobs) { [FactoryGirl.create(:print_job)] }

    it "assigns print jobs" do
      spree_get :index
      expect(assigns[:print_jobs]).to eq(print_jobs)
    end
  end

  describe "#show" do
    let(:print_job) { FactoryGirl.create(:print_job) }

    it "returns the PDF" do
      allow(Spree::PrintJob).to receive(:find).with(print_job.to_param).and_return(print_job)
      expect(print_job).to receive(:pdf).and_return("pdf")
      spree_get :show, :id => print_job.id

      expect(response.body).to eq("pdf")
      expect(response.headers["Content-Type"]).to eq("application/pdf")
      expect(response.headers["Content-Disposition"]).to eq("inline; filename=\"invoice.pdf\"")
    end
  end
end
