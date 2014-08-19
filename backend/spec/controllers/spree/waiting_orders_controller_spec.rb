require 'spec_helper'

describe Spree::Admin::WaitingOrdersController, type: :controller do
  stub_authorization!
  let(:box_group) { create(:product_group, name: 'box')}
  let(:small_box) { create(:product, product_type: create(:product_type_packaging), individual_sale: false, product_group_id: box_group.id) }
  let(:params) { build_valid_params }
  let(:outcome)   { OpenStruct.new(:success? => true) }

  context "#index" do
    it "should load all boxes in the system" do
      allow(Spree::Parcel).to receive(:find_boxes).and_return(:boxes)
      spree_get :index
      expect(assigns[:all_boxes]).to eq(:boxes)
    end

    it "assigns the print batch size" do
      spree_get :index
      expect(assigns[:batch_size]).to eq(Spree::BulkOrderPrintingService::BATCH_SIZE)
    end

    it "assigns the number of unprinted invoices" do
      pending('cannot make factory work with stock_location')
      create_list(:order_ready_to_ship, 2)
      spree_get :index
      expect(assigns[:unprinted_invoice_count]).to eq(2)
    end

    it "assigns the number of unprinted stickers" do
      pending('cannot make factory work with stock_location')
      create_list(:invoice_printed_order, 3)
      spree_get :index
      expect(assigns[:unprinted_image_count]).to eq(3)
    end

    context "with a q params" do
      let(:orders) {
        2.times.map { |i| create(:order_ready_to_ship, :batch_print_id => i) }
      }

      it "assigns a single order" do
        pending('cannot make factory work with stock_location')
        spree_get :index, q: {batch_id_eq: orders.last.batch_print_id}
        expect(assigns[:collection]).to eq([orders.last])
      end
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
    let(:list_of_orders) { [create(:order)] }
    let(:result)         { double(:result => :pdf, :success? => true) }
    before do
      subject.stub(:load_orders_waiting).and_return( list_of_orders )
    end

    [ :invoices, :image_stickers].each do |action|
      it "renders all #{action}" do
        expect(Spree::BulkOrderPrintingService).to receive(:run).with(pdf: action).and_return(result)
        spree_get action, format: :pdf
        expect(response.body).to eq("pdf")
        expect(response.headers["Content-Type"]).to eq("application/pdf")
        expect(response.headers["Content-Disposition"]).to eq("inline; filename=\"#{action}.pdf\"")
      end
    end

  end
  context "#create_and_allocate_consignment" do
    let(:outcome)   { OpenStruct.new(:success? => true, :result => :pdf) }

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
