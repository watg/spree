require 'spec_helper'
describe Spree::StockTransferService::Create do

  describe '#execute' do
    let(:subject) { described_class }
    let(:supplier) { create(:supplier) }
    let(:variant) { create(:base_variant) }
    let(:quantity) { 1 }
    let(:reference) { 'test' }
    let(:stock_location_1) {create(:stock_location)}
    let!(:stock_item_1) {create(:stock_item, stock_location: stock_location_1, variant: variant, supplier: supplier )}
    let(:stock_location_2) {create(:stock_location)}
    let(:transfer_source_location_id) { stock_location_1.id }
    let(:transfer_destination_location_id) { stock_location_2.id }
    
    let(:params) { {
      variants: [variant.id],
      suppliers: [supplier.id],
      quantities: [quantity],
      reference: reference,
      transfer_source_location_id: transfer_source_location_id,
      transfer_destination_location_id: transfer_destination_location_id
    } }

    it "creates a stock transfer" do
      expect do
        outcome = subject.run(params)
        expect(outcome.valid?).to be true
        transfer = outcome.result
        expect(transfer).to be_kind_of Spree::StockTransfer
      end.to change(Spree::StockTransfer, :count).by 1
    end

    context "same stock transfer is put through twice" do
      it "does not create duplicate stock transfers" do
        subject.run(params)
        expect do
          outcome = subject.run(params)
          expect(outcome.valid?).to be false
        end.to change(Spree::StockTransfer, :count).by 0
      end
    end

    context "params are not supplied" do
      it "returns an error if suppliers not present" do
        params[:suppliers] = nil 
        outcome = subject.run(params)
        expect(outcome.errors.messages).to include(:suppliers => ["is required"])
        expect(outcome.invalid?).to be true
      end

      it "returns an error if variants not present" do
        params[:variants] = nil 
        outcome = subject.run(params)
        expect(outcome.errors.messages).to include(:variants => ["is required"])
        expect(outcome.invalid?).to be true
      end

      it "returns an error if quantities not present" do
        params[:quantities] = nil 
        outcome = subject.run(params)
        expect(outcome.errors.messages).to include(:quantities => ["is required"])
        expect(outcome.invalid?).to be true
      end

      it "returns an error if reference not present" do
        params[:reference] = nil 
        outcome = subject.run(params)
        expect(outcome.errors.messages).to include(:reference => ["is required"])
        expect(outcome.invalid?).to be true
      end

      it "returns an error if transfer_source_location_id is not present" do
        params[:transfer_source_location_id] = nil 
        outcome = subject.run(params)
        expect(outcome.errors.messages).to eq(:transfer_source_location_id => ["is required"])
        expect(outcome.invalid?).to be true
      end

      it "returns an error if transfer_destination_location_id is not present" do
        params[:transfer_destination_location_id] = nil 
        outcome = subject.run(params)
        expect(outcome.errors.messages).to eq(:transfer_destination_location_id => ["is required"])
        expect(outcome.invalid?).to be true
      end
    end



    context "params supplied but contain nil values" do
      it "returns an error if suppliers contains nil values" do
        params[:suppliers] = [nil] 
        outcome = subject.run(params)
        expect(outcome.errors.messages).to include(:suppliers => ["is required"])
        expect(outcome.invalid?).to be true
      end

      it "returns an error if variants contains nil values" do
        params[:variants] = [nil] 
        outcome = subject.run(params)
        expect(outcome.errors.messages).to include(:variants => ["is required"])
        expect(outcome.invalid?).to be true
      end

      it "returns an error if quantities contains nil values" do
        params[:quantities] = [nil] 
        outcome = subject.run(params)
        expect(outcome.errors.messages).to include(:quantities => ["is required"])
        expect(outcome.invalid?).to be true
      end
    end

  end

end
