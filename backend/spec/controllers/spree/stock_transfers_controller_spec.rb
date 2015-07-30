require "spec_helper"

module Spree
  describe Admin::StockTransfersController, type: :controller do
    stub_authorization!

    let!(:stock_transfer1) do
      StockTransfer.create do |transfer|
        transfer.source_location_id = 1
        transfer.destination_location_id = 2
        transfer.reference = "PO 666"
      end
    end

    let!(:stock_transfer2) do
      StockTransfer.create do |transfer|
        transfer.source_location_id = 3
        transfer.destination_location_id = 4
        transfer.reference = "P01 666"
      end
    end

    context "#index" do
      it "gets all transfers without search criteria" do
        spree_get :index
        expect(assigns[:stock_transfers].count).to eq 2
      end

      it "searches by source location" do
        spree_get :index, q: { source_location_id_eq: 1 }
        expect(assigns[:stock_transfers].count).to eq 1
        expect(assigns[:stock_transfers]).to include(stock_transfer1)
      end

      it "searches by destination location" do
        spree_get :index, q: { destination_location_id_eq: 4 }
        expect(assigns[:stock_transfers].count).to eq 1
        expect(assigns[:stock_transfers]).to include(stock_transfer2)
      end
    end

    context "#create" do
      let(:params) do
        {
          "reference" => "",
          "transfer_source_location_id" => "1",
          "transfer_destination_location_id" => "1",
          "transfer_variant" => "1",
          "transfer_variant_quantity" => "1",
          "suppliers" => ["1"],
          "variants" => ["1"],
          "quantities" => ["1"]
        }
      end

      context "with correct params" do
        let(:outcome) { OpenStruct.new(:valid? => true, :result =>  stock_transfer1) }

        before { allow(Spree::StockTransferService::Create).to receive(:run).and_return(outcome) }

        it "calls tranfer service and returns success message" do
          spree_post :create, params.dup
          expect(Spree::StockTransferService::Create).to have_received(:run).with(hash_including(params))
          expect(flash[:success]).to be_present
        end
      end

      context "with incorrect params" do
        let(:errors) { double(full_messages: ["foobar"]) }
        let(:unsuccessful_outcome) { OpenStruct.new(:valid? => false, :errors =>  errors) }

        before { allow(Spree::StockTransferService::Create).to receive(:run).and_return(unsuccessful_outcome) }

        it "calls the transfer service with given params and returns an error message" do
          spree_post :create, params.dup
          expect(Spree::StockTransferService::Create).to have_received(:run).with(hash_including(params))
          expect(flash[:error]).to be_present
        end
      end
    end
  end
end
