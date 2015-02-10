require 'spec_helper'

describe Spree::Admin::WaitingOrdersController, type: :controller do
  stub_authorization!
  let(:small_box) { create(:product, product_type: create(:product_type_packaging), individual_sale: false) }
  let(:params) { build_valid_params }
  let(:outcome)   { OpenStruct.new(:valid? => true) }

  context "#index" do
    it "should load all boxes in the system" do
      allow(Spree::Parcel).to receive(:find_boxes).and_return(:boxes)
      spree_get :index
      expect(assigns[:all_boxes]).to eq(:boxes)
    end

    it "should use filter params" do
      filter_params={'first_filter'=> 'test1','second_filter'=>'test2'}
      expect(Spree::Order).to receive(:ransack).with(filter_params).and_call_original
      spree_get :index, { q: filter_params }
    end

    it "assigns the print batch size, number of unprinted invoices and stickers" do
      expect(Spree::Order).to receive(:unprinted_invoices).and_return(["order1"])
      expect(Spree::Order).to receive(:unprinted_image_stickers).and_return(["order2", "order3"])

      spree_get :index
      expect(assigns[:batch_size]).to eq(Spree::BulkOrderPrintingService::BATCH_SIZE)
      expect(assigns[:unprinted_invoice_count]).to eq(1)
      expect(assigns[:unprinted_image_count]).to eq(2)
      expect(assigns[:collection]).to be_empty
    end
  end

  context "#update" do
    let(:expected_params) do
      {
        order_id: '1',
        box_id: small_box.id.to_s,
        quantity: '2'
      }
    end

    it "should call add parcel to order service" do
      expect(Spree::AddParcelToOrderService).to receive(:run).with(expected_params).and_return(outcome)
      spree_put :update, params
    end

    context "with a batch id" do
      it "redirects to the batch id" do
        q = {q: {id_eq: 1234}}
        allow(Spree::AddParcelToOrderService).to receive(:run).with(expected_params).and_return(outcome)
        spree_put :update, params.merge(q)
        expect(:response).to redirect_to(spree.admin_waiting_orders_path(q))
      end
    end
  end

  context "#destroy" do
    it "should delete all parcels for a specific type of box" do
      expected_params = {
        order_id: '1',
        box_id: small_box.id.to_s,
        quantity: '2'
      }
      Spree::RemoveParcelToOrderService.should_receive(:run).with(expected_params).and_return(outcome)

      spree_delete :destroy, params
    end
  end

  context "PDF generation" do
    let(:list_of_orders) { double.as_null_object }
    let(:outcome) { OpenStruct.new(:valid? => true, :result => :pdf) }

    it "renders all invoices" do
      allow(Spree::Order).to receive(:unprinted_invoices).and_return list_of_orders
      expect_any_instance_of(Spree::BulkOrderPrintingService).to receive(:print_invoices).with(list_of_orders).and_return(outcome)

      spree_put :invoices, format: :pdf
      expect(response.body).to eq("pdf")
      expect(response.headers["Content-Type"]).to eq("application/pdf")
      expect(response.headers["Content-Disposition"]).to eq("inline; filename=\"invoices.pdf\"")
    end

    it "renders all image_stickers" do
      allow(Spree::Order).to receive(:unprinted_image_stickers).and_return list_of_orders
      expect_any_instance_of(Spree::BulkOrderPrintingService).to receive(:print_image_stickers).with(list_of_orders).and_return(outcome)

      spree_put :image_stickers, format: :pdf
      expect(response.body).to eq("pdf")
      expect(response.headers["Content-Type"]).to eq("application/pdf")
      expect(response.headers["Content-Disposition"]).to eq("inline; filename=\"image_stickers.pdf\"")
    end
  end


  context "#create_and_allocate_consignment" do
    let(:outcome) { OpenStruct.new(:valid? => true, :result => :pdf) }

    it "submits order details to metapack" do
      Spree::CreateAndAllocateConsignmentService.should_receive(:run).with(order_id: '1').and_return(outcome)
      spree_post :create_and_allocate_consignment, id: 1, page: 2
    end

    it "renders the result as a PDF" do
      allow(Spree::CreateAndAllocateConsignmentService).to receive(:run).with(order_id: '1').and_return(outcome)
      spree_post :create_and_allocate_consignment, id: 1, page: 2
      expect(response.body).to eq("pdf")
      expect(response.headers["Content-Type"]).to eq("application/pdf")
      expect(response.headers["Content-Disposition"]).to eq("inline; filename=\"label.pdf\"")
    end
  end

# ---------------------------------------------------
  def build_valid_params
    {
      id:  1,
      box: {id:  small_box.id, quantity:  2}
    }
  end
end
