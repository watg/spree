require 'spec_helper'

describe Spree::Api::ShipmentsController do
  render_views
  let!(:shipment) { create(:shipment) }
  let!(:attributes) { [:id, :tracking, :number, :cost, :shipped_at, :stock_location_name, :order_id, :shipping_rates, :shipping_methods] }

  before do
    stub_authentication!
  end

  let!(:resource_scoping) { { :order_id => shipment.order.to_param, :id => shipment.to_param } }

  context "as a non-admin" do
    it "cannot make a shipment ready" do
      api_put :ready
      assert_unauthorized!
    end

    it "cannot make a shipment shipped" do
      api_put :ship
      assert_unauthorized!
    end
  end

  context "as an admin" do
    let!(:order) { shipment.order }
    let!(:stock_location) { create(:stock_location_with_items) }
    let!(:variant) { create(:variant) }
    sign_in_as_admin!

    it 'can create a new shipment' do
      v = stock_location.stock_items.first.variant
      assembly_selection = {1 => 23, 3 => 1034}
      params = {
        variant_id: v.to_param,
        order_id: order.number,
        stock_location_id: stock_location.to_param,
        selected_variants: assembly_selection
      }

      api_post :create, params
      response.status.should == 200
      json_response.should have_attributes(attributes)
    end

    it 'can update a shipment' do
      params = {
        shipment: {
          stock_location_id: stock_location.to_param
        }
      }

      api_put :update, params
      response.status.should == 200
      json_response['stock_location_name'].should == stock_location.name
    end

    it "can make a shipment ready" do
      Spree::Order.any_instance.stub(:paid? => true, :complete? => true, :physical_line_items => [double])
      api_put :ready
      json_response.should have_attributes(attributes)
      json_response["state"].should == "ready"
      shipment.reload.state.should == "ready"
    end

    it "cannot make a shipment ready if the order is unpaid" do
      Spree::Order.any_instance.stub(:paid? => false)
      api_put :ready
      json_response["error"].should == "Cannot ready shipment."
      response.status.should == 422
    end

    context 'for completed shipments' do
      let(:order) { create :completed_order_with_totals }
      let!(:resource_scoping) { { :order_id => order.to_param, :id => order.shipments.first.to_param } }

      it 'adds a variant to a shipment' do
        assembly_selection = {23 => 987 , 4 => 232}

        api_put :add, { variant_id: variant.to_param, quantity: 2, selected_variants: assembly_selection }
        response.status.should == 200
        json_response['manifest'].detect { |h| h['variant']['id'] == variant.id }["quantity"].should == 2
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
          json_response['manifest'].detect { |h| h['variant']['id'] == variant_part.id }["quantity"].should == 4 # line_item quantity: 2 x 2
          response.status.should == 200

          api_put :remove, { variant_id: variant_assembly.to_param, quantity: 1, selected_variants: assembly_selection }
          json_response['manifest'].detect { |h| h['variant']['id'] == variant_part.id }["quantity"].should == 2 # line_item quantity: 2 x 2
          response.status.should == 200
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
          json_response['manifest'].detect { |h| h['variant']['id'] == required_part1.id }["quantity"].should == 4 # line_item quantity: 2 x 2
          response.status.should == 200

          api_put :remove, { variant_id: variant.to_param, quantity: 1 }
          json_response['manifest'].detect { |h| h['variant']['id'] == required_part1.id }["quantity"].should == 2 # line_item quantity: 2 x 2
          response.status.should == 200
        end

      end

      it 'removes a variant from a shipment' do
        order.contents.add(variant, 2)

        api_put :remove, { variant_id: variant.to_param, quantity: 1 }
        response.status.should == 200
        json_response['manifest'].detect { |h| h['variant']['id'] == variant.id }["quantity"].should == 1
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
            response.status.should == 200
            json_response['manifest'].detect { |h| h['variant']['id'] == line_item.variant.id }["quantity"].should == 4
          end

          it 'removes a line_item to a shipment' do
            api_put :remove_by_line_item, { line_item_id: line_item.id, quantity: 1  }
            response.status.should == 200
            json_response['manifest'].detect { |h| h['variant']['id'] == line_item.variant.id }["quantity"].should == 1
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
            response.status.should == 200
            json_response['manifest'].detect { |h| h['variant']['id'] == line_item.variant.id }.should be_nil
            json_response['manifest'].detect { |h| h['variant']['id'] == variant_part.id }["quantity"].should == 16
          end

          it 'removes a line_item to a shipment' do
            api_put :remove_by_line_item, { line_item_id: line_item.id, quantity: 1  }
            response.status.should == 200
            json_response['manifest'].detect { |h| h['variant']['id'] == line_item.variant.id }.should be_nil
            json_response['manifest'].detect { |h| h['variant']['id'] == variant_part.id }["quantity"].should == 4
          end

        end

      end

    end

    context "can transition a shipment from ready to ship" do
      before do
        Spree::Order.any_instance.stub(:paid? => true, :complete? => true, :physical_line_items => [double])
        # For the shipment notification email
        Spree::Config[:mails_from] = "spree@example.com"

        shipment.update!(shipment.order)
        shipment.state.should == "ready"
        Spree::ShippingRate.any_instance.stub(:cost => 5)
      end

      it "can transition a shipment from ready to ship" do
        shipment.reload
        api_put :ship, :order_id => shipment.order.to_param, :id => shipment.to_param, :shipment => { :tracking => "123123" }
        json_response.should have_attributes(attributes)
        json_response["state"].should == "shipped"
      end
    end
  end
end
