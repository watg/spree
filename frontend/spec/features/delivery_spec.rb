require "spec_helper"

describe "Delivery", type: :feature, js: true do
  let!(:country) { create(:country, states_required: true) }
  let!(:state) { create(:state, country: country) }
  let!(:stock_location) { create(:stock_location) }
  let!(:payment_method) { create(:payment_method) }
  let!(:zone) { Spree::Zone.first || create(:zone) }
  let!(:user) { create(:user) }

  let!(:order) do
    order = OrderWalkthrough.up_to(:delivery)
    order.stub :confirmation_required? => true
    order.user = user
    order.update!
    order
  end

  before(:each) do
    allow(Flip).to receive(:on?).with(:shipping_options).and_return(true)
    allow(Flip).to receive(:on?).with(:suites_feature).and_return(false)

    Spree::CheckoutController.any_instance.stub(current_order: order)
    Spree::CheckoutController.any_instance.stub(:check_authorization)
    allow_any_instance_of(Spree::OrdersController).to receive_messages(try_spree_current_user: user)
    order.reload
  end

  context "when a free shipping promo code is added" do
    let(:promotion) { Spree::Promotion.create(name: "Free Shipping", code: "FREEMANGAL") }
    let!(:action) { Spree::Promotion::Actions::FreeShipping.create(promotion: promotion) }

    before do
      action.shipping_methods << order.shipments.first.selected_shipping_rate.shipping_method
    end

    it "applies to the relevant shipping rate" do
      visit spree.checkout_state_path("delivery")

      # default selected shippng rate
      expect(page).to have_content "UPS Ground"
      expect(find_field("UPS Ground")).to be_checked

      within ".shipping-total-table" do
        expect(page).to have_content "Shipping total:"
        expect(page).to have_content "$10.00"
      end

      #  Adds coupon code
      within ".coupons-updates" do
        fill_in('order[coupon_code]', :with => 'FREEMANGAL')
        find_button('Update bag').click
      end

      within ".shipping-total-table" do
        expect(page).to have_content "Shipping total:"
        expect(page).to have_content "$0.00"
      end
    end
  end

  context "with multiple shipping rates" do
    let(:shipping_method_2) { create(:shipping_method, name: "second shipping rate") }
    let!(:second_shipping_rate) do
      Spree::ShippingRate.create(
        cost: 100,
        selected: false,
        shipping_method: shipping_method_2,
        shipment: order.shipments.first
      )
    end

    it "can switch between the shipping rates and recalculate the shipping cost" do
      visit spree.checkout_state_path("delivery")

      # default selected shippng rate
      expect(page).to have_content "UPS Ground"
      find_field("UPS Ground").should be_checked

      within ".delivery_options" do
        expect(page).to have_content "100.00"
        expect(page).to have_content "second shipping rate"
        find_field("second shipping rate").should_not be_checked
      end

      within ".shipping-total-table" do
        expect(page).to have_content "Shipping total:"
        expect(page).to have_content "$10.00"
      end

      choose("second shipping rate")

      find_field("second shipping rate").should be_checked
      find_field("UPS Ground").should_not be_checked

      within ".shipping-total-table" do
        expect(page).to have_content "Shipping total:"
        expect(page).to have_content "$100.00"
      end
    end

    context "when a free shipping promotion is present" do
      let(:promotion) { Spree::Promotion.create(name: "Free Shipping") }
      let!(:action) { Spree::Promotion::Actions::FreeShipping.create(promotion: promotion) }

      before do
        action.shipping_methods << second_shipping_rate.shipping_method
        # apply free shiping promotions to eligible shipping rates
        order.apply_free_shipping_promotions
      end

      it "applies to the relevant shipping rate" do
        visit spree.checkout_state_path("delivery")

        # default selected shippng rate
        expect(page).to have_content "UPS Ground"
        expect(find_field("UPS Ground")).to be_checked

        # unselected free delivery option
        within ".delivery_options" do
          expect(page).to have_content "second shipping rate"
          expect(page).to have_content "FREE"
          expect(find_field("second shipping rate")).to_not be_checked
        end

        within ".shipping-total-table" do
          expect(page).to have_content "Shipping total:"
          expect(page).to have_content "$10.00"
        end

        choose("second shipping rate")

        expect(find_field("second shipping rate")).to be_checked
        expect(find_field("UPS Ground")).to_not be_checked

        within ".shipping-total-table" do
          expect(page).to have_content "Shipping total:"
          expect(page).to have_content "$0.00"
        end
      end
    end
  end
end
