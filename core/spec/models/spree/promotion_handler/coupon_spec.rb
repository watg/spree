require 'spec_helper'

module Spree
  module PromotionHandler
    describe Coupon do
      let(:order) { double("Order", coupon_code: "10off").as_null_object }

      subject { Coupon.new(order) }

      it "returns self in apply" do
        expect(subject.apply).to be_a Coupon
      end


      context "with valid gift card" do
        let(:gift_card) { create(:gift_card, value: 10) }
        let(:order_with_giftcard) { gift_card.buyer_order }
        let(:giftcard_coupon) {Coupon.new(order_with_giftcard)}

        before { order_with_giftcard.coupon_code = gift_card.code }

        it "sutracts gift card amount from order total" do
          # due to convuluted factories, instead of stating an order value,
          # value it determined through the order total attributed to GifrCard Factory
          original_order_total = gift_card.buyer_order.total

          giftcard_coupon.apply
          expect(order_with_giftcard.reload.total).to eq original_order_total - gift_card.value
        end
      end

      context "coupon code promotion doesnt exist" do
        before { Promotion.create name: "promo", :code => nil }

        it "doesnt fetch any promotion" do
          expect(subject.promotion).to be_blank
        end

        context "with no actions defined" do
          before { Promotion.create name: "promo", :code => "10off" }

          it "populates error message" do
            subject.apply
            expect(subject.error).to eq Spree.t(:coupon_code_not_found)
          end
        end
      end

      context "existing coupon code promotion" do
        let!(:promotion) { Promotion.create name: "promo", :code => "10off"  }
        let!(:action) { Promotion::Actions::CreateItemAdjustments.create(promotion: promotion, calculator: calculator) }
        let(:calculator) { Calculator::FlatRate.new(preferred_amount: [{type: :integer, name: "USD", value: 10}]) }

        it "fetches with given code" do
          expect(subject.promotion).to eq promotion
        end

        context "with a per-item adjustment action" do
          let(:order) { create(:order_with_line_items, :line_items_count => 3) }

          context "right coupon given" do
            context "with correct coupon code casing" do
              before { order.stub :coupon_code => "10off" }

              it "successfully activates promo" do
                order.total.should == 130
                subject.apply
                expect(subject.success).to be_present
                order.line_items.each do |line_item|
                  line_item.adjustments.count.should == 1
                end
                # Ensure that applying the adjustment actually affects the order's total!
                order.reload.total.should == 100
              end

              it "coupon already applied to the order" do
                subject.apply
                expect(subject.success).to be_present
                subject.apply
                expect(subject.error).to eq Spree.t(:coupon_code_already_applied)
              end
            end

            # Regression test for #4211
            context "with incorrect coupon code casing" do
              before { order.stub :coupon_code => "10OFF" }
              it "successfully activates promo" do
                order.total.should == 130
                subject.apply
                expect(subject.success).to be_present
                order.line_items.each do |line_item|
                  line_item.adjustments.count.should == 1
                end
                # Ensure that applying the adjustment actually affects the order's total!
                order.reload.total.should == 100
              end
            end
          end

          context "coexists with a non coupon code promo" do
            let!(:order) { Order.create }
            let(:variant) { create(:variant) }

            before do
              order.stub :coupon_code => "10off"
              calculator = Calculator::FlatRate.new(preferred_amount: [{type: :integer, name: "USD", value: 10}])
              general_promo = Promotion.create name: "General Promo"
              general_action = Promotion::Actions::CreateItemAdjustments.create(promotion: general_promo, calculator: calculator)
              variant.price_normal_in('USD').amount = 19.99
              order.contents.add variant
            end

            # regression spec for #4515
            it "successfully activates promo" do
              subject.apply
              expect(subject).to be_successful
            end
          end
        end

        context "with a free-shipping adjustment action" do
          let!(:action) { Promotion::Actions::FreeShipping.create(promotion: promotion) }
          context "right coupon code given" do
            let(:order) { create(:order_with_line_items, :line_items_count => 3) }

            before { order.stub :coupon_code => "10off" }

            it "successfully activates promo" do
              order.total.should == 130
              subject.apply
              expect(subject.success).to be_present

              order.shipment_adjustments.count.should == 1
            end

            it "coupon already applied to the order" do
              subject.apply
              expect(subject.success).to be_present
              subject.apply
              expect(subject.error).to eq Spree.t(:coupon_code_already_applied)
            end
          end
        end

        context "with a whole-order adjustment action" do
          let!(:action) { Promotion::Actions::CreateAdjustment.create(promotion: promotion, calculator: calculator) }
          context "right coupon given" do
            let(:order) { create(:order) }
            let(:calculator) { Calculator::FlatRate.new(preferred_amount: [{type: :integer, name: "USD", value: 10}]) }

            before do
              order.stub({
                :coupon_code => "10off",
                # These need to be here so that promotion adjustment "wins"
                :item_total => 50,
                :ship_total => 10
              })
            end

            it "successfully activates promo" do
              subject.apply
              expect(subject.success).to be_present
              order.adjustments.count.should == 1
            end

            it "coupon already applied to the order" do
              subject.apply
              expect(subject.success).to be_present
              subject.apply
              expect(subject.error).to eq Spree.t(:coupon_code_already_applied)
            end

            it "coupon fails to activate" do
              Spree::Promotion.any_instance.stub(:activate).and_return false
              subject.apply
              expect(subject.error).to eq Spree.t(:coupon_code_unknown_error)
            end


            it "coupon code hit max usage" do
              promotion.update_column(:usage_limit, 1)
              coupon = Coupon.new(order)
              coupon.apply
              expect(coupon.successful?).to be true

              order_2 = create(:order)
              order_2.stub :coupon_code => "10off"
              coupon = Coupon.new(order_2)
              coupon.apply
              expect(coupon.successful?).to be false
              expect(coupon.error).to eq Spree.t(:coupon_code_max_usage)
            end

            context "when the a new coupon is less good" do
              let!(:action_5) { Promotion::Actions::CreateAdjustment.create(promotion: promotion_5, calculator: calculator_5) }
              let(:calculator_5) { Calculator::FlatRate.new(preferred_amount: 5) }
              let!(:promotion_5) { Promotion.create name: "promo", :code => "5off"  }

              it 'notifies of better deal' do
                subject.apply
                order.stub( { coupon_code: '5off' } )
                coupon = Coupon.new(order).apply
                expect(coupon.error).to eq Spree.t(:coupon_code_better_exists)
              end
            end
          end
        end

        context "for an order with taxable line items" do
          before(:each) do
            @country = create(:country)
            @zone = create(:zone, :name => "Country Zone", :default_tax => true, :zone_members => [])
            @zone.zone_members.create(:zoneable => @country)
            @category = Spree::TaxCategory.create :name => "Taxable Foo"
            @rate1 = Spree::TaxRate.create(
                :amount => 0.10,
                :calculator => Spree::Calculator::DefaultTax.create,
                :tax_category => @category,
                :zone => @zone,
                :currency => "USD"
            )

            @order = Spree::Order.create!
            @order.stub :coupon_code => "10off"
          end
          context "and the product price is less than promo discount" do
            before(:each) do
              3.times do |i|
                taxable = create(:product, :tax_category => @category)
                taxable.master.price_normal_in('USD').amount = 9.0
                @order.contents.add(taxable.master, 1)
              end
            end
            it "successfully applies the promo" do
              # 3 * (9 + 0.9)
              @order.total.should == 29.7
              coupon = Coupon.new(@order)
              coupon.apply
              expect(coupon.success).to be_present
              # 3 * ((9 - [9,10].min) + 0)
              @order.reload.total.should == 0
              @order.additional_tax_total.should == 0
            end
          end
          context "and the product price is greater than promo discount" do
            before(:each) do
              3.times do |i|
                taxable = create(:product, :tax_category => @category)
                taxable.master.price_normal_in('USD').amount = 11.0
                @order.contents.add(taxable.master, 2)
              end
            end
            it "successfully applies the promo" do
              # 3 * (22 + 2.2)
              @order.total.to_f.should == 72.6
              coupon = Coupon.new(@order)
              coupon.apply
              expect(coupon.success).to be_present
              # 3 * ( (22 - 10) + 1.2)
              @order.reload.total.should == 39.6
              @order.additional_tax_total.should == 3.6
            end
          end
          context "and multiple quantity per line item" do
            before(:each) do
              twnty_off = Promotion.create name: "promo", :code => "20off"
              twnty_off_calc = Calculator::FlatRate.new(preferred_amount: [{type: :integer, name: "USD", value: 20}])
              Promotion::Actions::CreateItemAdjustments.create(promotion: twnty_off,
                                                               calculator: twnty_off_calc)

              @order.unstub :coupon_code
              @order.stub :coupon_code => "20off"
              3.times do |i|
                taxable = create(:product, :tax_category => @category)
                taxable.master.price_normal_in('USD').amount = 10.0
                @order.contents.add(taxable.master, 2)
              end
            end
            it "successfully applies the promo" do
              # 3 * ((2 * 10) + 2.0)
              @order.total.to_f.should == 66
              coupon = Coupon.new(@order)
              coupon.apply
              expect(coupon.success).to be_present
              # 0
              @order.reload.total.should == 0
              @order.additional_tax_total.should == 0
            end
          end
        end

        context "with a CreateLineItems action" do
          let!(:variant) { create(:variant) }
          let!(:action) { Promotion::Actions::CreateLineItems.create(promotion: promotion, promotion_action_line_items_attributes: { :'0' => { variant_id: variant.id }}) }
          let(:order) { create(:order) }

          before do
            order.stub(coupon_code: "10off")
          end

          it "successfully activates promo" do
            subject.apply
            expect(subject.success).to be_present
            expect(order.line_items.pluck(:variant_id)).to include(variant.id)
          end
        end

      end
    end
  end
end
