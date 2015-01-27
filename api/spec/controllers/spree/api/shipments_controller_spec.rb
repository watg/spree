require 'spec_helper'

describe Spree::Api::ShipmentsController, :type => :controller do
  render_views
  let!(:shipment) { create(:shipment) }
  let!(:attributes) { [:id, :tracking, :number, :cost, :shipped_at, :stock_location_name, :order_id, :shipping_rates, :shipping_methods] }

  before do
    stub_authentication!
  end

  let!(:resource_scoping) { { id: shipment.to_param, shipment: { order_id: shipment.order.to_param } } }

  context "as a non-admin" do
    it "cannot make a shipment ready" do
      api_put :ready
      assert_not_found!
    end

    it "cannot make a shipment shipped" do
      api_put :ship
      assert_not_found!
    end
  end

  context "as an admin" do
    let!(:order) { shipment.order }
    let!(:stock_location) { create(:stock_location_with_items) }
    let!(:variant) { create(:variant) }

    sign_in_as_admin!

    # Start writing this spec a bit differently than before....
    describe 'POST #create' do
      let(:v) { stock_location.stock_items.first.variant }
      let(:assembly_selection) do 
        {1 => 23, 3 => 1034}
      end
      let(:params) do
        {
          variant_id: v.to_param,
          order_id: order.number,
          shipment: { order_id: order.number },
          stock_location_id: stock_location.to_param,
          selected_variants: assembly_selection
        }
      end 
      
      subject do 
        api_post :create, params
      end

      #[:variant_id, :stock_location_id].each do |field|
      [:variant_id].each do |field|
        context "when #{field} is missing" do
          before do
            params.delete(field)
          end

          it 'should return proper error' do
            subject
            expect(response.status).to eq(422)
            expect(json_response['exception']).to eq("param is missing or the value is empty: #{field.to_s}")
          end
        end
      end

      it 'should create a new shipment' do
        expect(subject).to be_ok
        expect(json_response).to have_attributes(attributes)
      end
    end

    it 'can update a shipment' do
      params = {
        shipment: {
          stock_location_id: stock_location.to_param
        }
      }

      api_put :update, params
      expect(response.status).to eq(200)
      expect(json_response['stock_location_name']).to eq(stock_location.name)
    end

    it "can make a shipment ready" do
      allow_any_instance_of(Spree::Order).to receive_messages(:paid? => true, :state => "complete", :complete? => true, :physical_line_items => [double])
      api_put :ready
      expect(json_response).to have_attributes(attributes)
      expect(json_response["state"]).to eq("ready")
      expect(shipment.reload.state).to eq("ready")
    end

    it "cannot make a shipment ready if the order is unpaid" do
      allow_any_instance_of(Spree::Order).to receive_messages(:paid? => false)
      api_put :ready
      expect(json_response["error"]).to eq("Cannot ready shipment.")
      expect(response.status).to eq(422)
    end

    context 'for completed shipments' do
      let(:order) { create :completed_order_with_totals }
      let!(:resource_scoping) { { id: order.shipments.first.to_param, shipment: { order_id: order.to_param } } }

      it 'adds a variant to a shipment' do
        assembly_selection = {23 => 987 , 4 => 232}

        api_put :add, { variant_id: variant.to_param, quantity: 2, selected_variants: assembly_selection }
        expect(response.status).to eq(200)
        expect(json_response['manifest'].detect { |h| h['variant']['id'] == variant.id }["quantity"]).to eq(2)
      end


      context "dynamic kits" do

        let(:variant) { create(:variant, amount: 60.00) }
        let(:product) { variant.product }
        let!(:variant_assembly) { create(:variant) }
        let!(:assembly_definition) { create(:assembly_definition, variant: variant_assembly) }
        let!(:variant_part)  { create(:base_variant, product: product) }
        let!(:price) { create(:price, variant: variant_part, price: 2.99, sale: false, is_kit: true, currency: 'USD') }
        let!(:adp) { create(:assembly_definition_part, assembly_definition: assembly_definition, product: product, count: 2, assembled: true) }
        let!(:adv) { create(:assembly_definition_variant, assembly_definition_part: adp, variant: variant_part) }

        it 'can add and remove quantity' do
          assembly_selection = {adp.id.to_s => variant_part.id}
          api_put :add, { variant_id: variant_assembly.to_param, quantity: 2, selected_variants: assembly_selection }
          expect(response.status).to eq(200)
          expect(json_response['manifest'].detect { |h| h['variant']['id'] == variant_part.id }["quantity"]).to eq(4) # line_item quantity: 2 x 2

          api_put :remove, { variant_id: variant_assembly.to_param, quantity: 1, selected_variants: assembly_selection }
          expect(response.status).to eq(200)
          expect(json_response['manifest'].detect { |h| h['variant']['id'] == variant_part.id }["quantity"]).to eq(2) # line_item quantity: 2 x 2
        end

      end

      context "static kits" do

        let(:variant) { create(:variant, amount: 60.00) }
        let(:product) { variant.product }
        let!(:required_part1) { create(:variant) }
        #let(:part1) { create(:variant) }

        before do
          # TODO: make old kits work with options
        #  product.add_part(part1, 1, true)
          product.add_part(required_part1, 2, false)
        end

        it 'can add and remove quantity' do
          api_put :add, { variant_id: variant.to_param, quantity: 2 }
          expect(response.status).to eq(200)
          expect(json_response['manifest'].detect { |h| h['variant']['id'] == required_part1.id }["quantity"]).to eq(4) # line_item quantity: 2 x 2

          api_put :remove, { variant_id: variant.to_param, quantity: 1 }
          expect(response.status).to eq(200)
          expect(json_response['manifest'].detect { |h| h['variant']['id'] == required_part1.id }["quantity"]).to eq(2) # line_item quantity: 2 x 2
        end
      end

      it 'removes a variant from a shipment' do
        order.contents.add(variant, 2)

        api_put :remove, { variant_id: variant.to_param, quantity: 1 }
        expect(response.status).to eq(200)
        expect(json_response['manifest'].detect { |h| h['variant']['id'] == variant.id }["quantity"]).to eq(1)
      end

      it 'removes a destroyed variant from a shipment' do
        order.contents.add(variant, 2)
        variant.destroy

        api_put :remove, { variant_id: variant.to_param, quantity: 1 }
        expect(response.status).to eq(200)
        expect(json_response['manifest'].detect { |h| h['variant']['id'] == variant.id }["quantity"]).to eq(1)
      end

      context 'adjust by line_items' do
        let(:order) { create :completed_order_with_totals }
        let(:line_item) { order.line_items.first }

        context "normal" do

          before do
            line_item.update_attributes(quantity: 2)
          end

          it 'adds a line_item to a shipment' do
            api_put :add_by_line_item, { line_item_id: line_item.id, quantity: 2  }
            expect(response.status).to eq(200)
            expect(json_response['manifest'].detect { |h| h['variant']['id'] == line_item.variant.id }["quantity"]).to eq(4)
          end

          it 'removes a line_item to a shipment' do
            api_put :remove_by_line_item, { line_item_id: line_item.id, quantity: 1  }
            expect(response.status).to eq(200)
            expect(json_response['manifest'].detect { |h| h['variant']['id'] == line_item.variant.id }["quantity"]).to eq(1)
          end

        end

        context "kit" do

          let(:variant_part) { create(:base_variant) }

          before do
            line_item.update_column(:quantity,  2)
            Spree::InventoryUnit.delete_all
            create(:line_item_part, optional: false, line_item: line_item, variant: variant_part, quantity: 3)
            create(:line_item_part, optional: true, line_item: line_item, variant: variant_part, quantity: 1)
            line_item.save
          end

          it 'adds a line_item to a shipment' do
            api_put :add_by_line_item, { line_item_id: line_item.id, quantity: 2  }
            expect(response.status).to eq(200)
            expect(json_response['manifest'].detect { |h| h['variant']['id'] == line_item.variant.id }).to be_nil
            expect(json_response['manifest'].detect { |h| h['variant']['id'] == variant_part.id }["quantity"]).to eq(16)
          end

          it 'removes a line_item to a shipment' do
            api_put :remove_by_line_item, { line_item_id: line_item.id, quantity: 1  }
            expect(response.status).to eq(200)
            expect(json_response['manifest'].detect { |h| h['variant']['id'] == line_item.variant.id }).to be_nil
            expect(json_response['manifest'].detect { |h| h['variant']['id'] == variant_part.id }["quantity"]).to eq(4)
          end

        end

      end

    end

    context "can transition a shipment from ready to ship" do
      before do
        allow_any_instance_of(Spree::Order).to receive_messages(:paid? => true, :state => "complete", :complete? => true, :physical_line_items => [double])
        # For the shipment notification email
        Spree::Config[:mails_from] = "spree@example.com"

        shipment.update!(shipment.order)
        expect(shipment.state).to eq("ready")
        allow_any_instance_of(Spree::ShippingRate).to receive_messages(:cost => 5)
      end

      it "can transition a shipment from ready to ship" do
        shipment.reload
        api_put :ship, id: shipment.to_param, shipment: { tracking: "123123", order_id: shipment.order.to_param }
        expect(json_response).to have_attributes(attributes)
        expect(json_response["state"]).to eq("shipped")
      end

    end

    describe '#mine' do
      subject do
        api_get :mine, format: 'json', params: params
      end

      let(:params) { {} }

      before { subject }

      context "the current api user is authenticated and has orders" do
        let(:current_api_user) { shipped_order.user }
        let(:shipped_order) { create(:shipped_order) }

        it 'succeeds' do
          expect(response.status).to eq 200
        end

        describe 'json output' do
          render_views

          let(:rendered_shipment_ids) { json_response['shipments'].map { |s| s['id'] } }

          it 'contains the shipments' do
            expect(rendered_shipment_ids).to match_array current_api_user.orders.flat_map(&:shipments).map(&:id)
          end
        end

        context 'with filtering' do
          let(:params) { {q: {order_completed_at_not_null: 1}} }

          let!(:incomplete_order) { create(:order, user: current_api_user) }

          it 'filters' do
            expect(assigns(:shipments).map(&:id)).to match_array current_api_user.orders.complete.flat_map(&:shipments).map(&:id)
          end
        end
      end

      context "the current api user is not persisted" do
        let(:current_api_user) { Spree.user_class.new }

        it "returns a 401" do
          expect(response.status).to eq(401)
        end
      end
    end

  end
end
