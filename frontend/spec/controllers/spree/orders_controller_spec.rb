require "spec_helper"

describe Spree::OrdersController, type: :controller do
  let(:user) { create(:user) }

  context "Order model mock" do
    let(:order) do
      Spree::Order.create
    end

    before do
      allow(controller).to receive_messages(try_spree_current_user: user)
    end

    context "#populate" do
      let(:item) { double("Item") }
      let(:variant) { create(:base_variant, amount: 60.00) }
      let(:target_id) { 45 }
      let(:options) { {} }
      let(:quantity) { 2 }

      let(:params) do
        {
          variant_id: variant.id,
          quantity: quantity,
          target_id: target_id,
          suite_tab_id: 2,
          suite_id: 1,
          options: options
        }
      end

      let(:item) { double("Item", errors: []) }
      let(:populator) { double("OrderPopulator", populate: item) }

      it "creates a new order when none specified" do
        expect(Spree::OrderPopulator).to receive(:new).and_return(populator)
        spree_post :populate, params
        expect(cookies.signed[:guest_token]).not_to be_blank
        expect(Spree::Order.find_by_guest_token(cookies.signed[:guest_token])).to be_persisted
      end

      it "creates a new order when none specified upon ajax call" do
        expect(Spree::OrderPopulator).to receive(:new).and_return(populator)
        spree_post :populate, params, format: :js
        expect(cookies.signed[:guest_token]).not_to be_blank
        expect(Spree::Order.find_by_guest_token(cookies.signed[:guest_token])).to be_persisted
      end

      context "with order" do
        before do
          allow(controller).to receive :check_authorization
          allow(controller).to receive_messages current_order: order
        end

        it "handles population" do
          expect(Spree::OrderPopulator).to receive(:new).with(order, params).and_return(populator)
          spree_post :populate, params.merge(order_id: order.id)
          expect(response).to redirect_to spree.cart_path
          expect(assigns[:item]).to eq(item)
        end

        it "handles ajax population" do
          expect(Spree::OrderPopulator).to receive(:new).with(order, params).and_return(populator)
          spree_post :populate, params.merge(order_id: order.id), format: :js
          expect(response).to redirect_to spree.cart_path
          expect(assigns[:item]).to eq(item)
        end

        it "shows an error if there is an error on item object" do
          item.errors << "Foobar"
          expect(Spree::OrderPopulator).to receive(:new).with(order, params).and_return(populator)
          spree_post :populate, params.merge(order_id: order.id), format: :js
          expect(response).to redirect_to spree.cart_path
          expect(assigns[:item]).to eq(item)
        end

        context "Validation error with service" do
          let(:errors) { double(full_messages: ["foobar"]) }
          let(:outcome) { OpenStruct.new(:valid? => false, :errors =>  errors)  }
          before { allow(Orders::PopulateService).to receive(:run).and_return(outcome) }

          it "shows an error when population fails" do
            error_message = "Populate Error: foobar"
            expect(Helpers::AirbrakeNotifier).to receive(:notify).with(error_message, kind_of(Hash))
            request.env["HTTP_REFERER"] = spree.root_path
            spree_post :populate, params.merge(order_id: order.id), format: :js
            expect(response).to redirect_to(spree.root_path)
          end
        end
      end
    end

    context "#update" do
      context "with authorization" do
        before do
          allow(controller).to receive :check_authorization
          allow(controller).to receive_messages current_order: order
        end

        it "renders the edit view (on failure)" do
          # email validation is only after address state
          order.update_column(:state, "delivery")
          spree_put :update, { order: { email: "" } },  order_id: order.id
          expect(response).to render_template :edit
        end

        it "redirects to cart path (on success)" do
          allow(order).to receive(:update_attributes).and_return true
          spree_put :update, {}, order_id: 1
          expect(response).to redirect_to(spree.cart_path)
        end
      end
    end

    context "#empty" do
      before do
        allow(controller).to receive :check_authorization
      end

      it "destroys line items in the current order" do
        allow(controller).to receive(:current_order).and_return(order)
        expect(order).to receive(:empty!)
        spree_put :empty
        expect(response).to redirect_to(spree.cart_path)
      end
    end

    # Regression test for #2750
    context "#update" do
      before do
        allow(user).to receive :last_incomplete_spree_order
        allow(controller).to receive :set_current_order
      end

      it "cannot update a blank order" do
        spree_put :update, order: { email: "foo" }
        expect(flash[:error]).to eq(Spree.t(:order_not_found))
        expect(response).to redirect_to(spree.root_path)
      end
    end
  end

  context "line items quantity is 0" do
    let(:order) { Spree::Order.create }
    let(:variant) { create(:variant) }
    let!(:line_item) { order.contents.add(variant, 1) }

    before do
      allow(controller).to receive(:check_authorization)
      allow(controller).to receive_messages(current_order: order)
    end

    it "removes line items on update" do
      expect(order.line_items.count).to eq 1
      spree_put :update, order: { line_items_attributes: { "0" => { id: line_item.id, quantity: 0 } } }
      expect(order.reload.line_items.count).to eq 0
    end
  end
end
