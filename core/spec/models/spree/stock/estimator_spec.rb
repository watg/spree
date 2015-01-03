require 'spec_helper'

module Spree
  module Stock
    describe Estimator do
      let!(:shipping_method) { create(:shipping_method) }
      let(:package) { build(:stock_package, contents: inventory_units.map { |i| ContentItem.new(inventory_unit) }) }
      let(:order) { build(:order_with_line_items) }
      let(:inventory_units) { order.inventory_units }

      subject { Estimator.new(order) }

      context "#shipping rates" do
        before(:each) do
          shipping_method.zones.first.members.create(:zoneable => order.ship_address.country)
          allow_any_instance_of(ShippingMethod).to receive_message_chain(:calculator, :available?).and_return(true)
          allow_any_instance_of(ShippingMethod).to receive_message_chain(:calculator, :compute).and_return(4.00)
          allow_any_instance_of(ShippingMethod).to receive_message_chain(:calculator, :preferences).and_return({:currency => "USD"})
          allow_any_instance_of(ShippingMethod).to receive_message_chain(:calculator, :marked_for_destruction?)

          allow(package).to receive_messages(:shipping_methods => [shipping_method])
        end

        it "returns shipping rates from a shipping method if the order's ship address is in the same zone" do
          shipping_rates = subject.shipping_rates(package)
          expect(shipping_rates.first.cost).to eq 4.00
        end

        it "does not return shipping rates from a shipping method if the order's ship address is in a different zone" do
          shipping_method.zones.each{|z| z.members.delete_all}
          shipping_rates = subject.shipping_rates(package)
          expect(shipping_rates).to eq([])
        end

        it "does not return shipping rates from a shipping method if the calculator is not available for that order" do
          allow_any_instance_of(ShippingMethod).to receive_message_chain(:calculator, :available?).and_return(false)
          shipping_rates = subject.shipping_rates(package)
          expect(shipping_rates).to eq([])
        end

        it "returns shipping rates from a shipping method if the currency matches the order's currency" do
          shipping_rates = subject.shipping_rates(package)
          expect(shipping_rates.first.cost).to eq 4.00
        end

        it "does not return shipping rates from a shipping method if the currency is different than the order's currency" do
          order.currency = "GBP"
          shipping_rates = subject.shipping_rates(package)
          expect(shipping_rates).to eq([])
        end

        it "does not return shipping rates if the shipping method's calculator raises an exception" do
          allow_any_instance_of(ShippingMethod).to receive_message_chain(:calculator, :available?).and_raise(Exception, "Something went wrong!")
          expect(subject).to receive(:log_calculator_exception)
          expect { subject.shipping_rates(package) }.not_to raise_error
        end

        it "sorts shipping rates by cost" do
          shipping_methods = 3.times.map { create(:shipping_method) }
          allow(shipping_methods[0]).to receive_message_chain(:calculator, :compute).and_return(5.00)
          allow(shipping_methods[1]).to receive_message_chain(:calculator, :compute).and_return(3.00)
          allow(shipping_methods[2]).to receive_message_chain(:calculator, :compute).and_return(4.00)

          allow(subject).to receive(:shipping_methods).and_return(shipping_methods)

          expect(subject.shipping_rates(package).map(&:cost)).to eq %w[3.00 4.00 5.00].map(&BigDecimal.method(:new))
        end

        context "general shipping methods" do
          let(:shipping_methods) { 2.times.map { create(:shipping_method) } }

          it "selects the most affordable shipping rate" do
            allow(shipping_methods[0]).to receive_message_chain(:calculator, :compute).and_return(5.00)
            allow(shipping_methods[1]).to receive_message_chain(:calculator, :compute).and_return(3.00)

            allow(subject).to receive(:shipping_methods).and_return(shipping_methods)

            expect(subject.shipping_rates(package).sort_by(&:cost).map(&:selected)).to eq [true, false]
          end

          it "selects the most affordable shipping rate and doesn't raise exception over nil cost" do
            allow(shipping_methods[0]).to receive_message_chain(:calculator, :compute).and_return(1.00)
            allow(shipping_methods[1]).to receive_message_chain(:calculator, :compute).and_return(nil)

            allow(subject).to receive(:shipping_methods).and_return(shipping_methods)

            subject.shipping_rates(package)
          end
        end

        context "involves backend only shipping methods" do
          let(:backend_method) { create(:shipping_method, display_on: "back_end") }
          let(:generic_method) { create(:shipping_method) }

          before do
            allow(backend_method).to receive_message_chain(:calculator, :compute).and_return(0.00)
            allow(generic_method).to receive_message_chain(:calculator, :compute).and_return(5.00)
            allow(subject).to receive(:shipping_methods).and_return([backend_method, generic_method])
          end

          it "does not return backend rates at all" do
            expect(subject.shipping_rates(package).map(&:shipping_method_id)).to eq([generic_method.id])
          end

          # regression for #3287
          it "doesn't select backend rates even if they're more affordable" do
            expect(subject.shipping_rates(package).map(&:selected)).to eq [true]
          end
        end

        context "includes tax adjustments if applicable" do
          let!(:tax_rate) { create(:tax_rate, zone: order.tax_zone) }

          before do
            Spree::ShippingMethod.all.each do |sm|
              sm.tax_category_id = tax_rate.tax_category_id
              sm.save
            end
            package.shipping_methods.map(&:reload)
          end


          it "links the shipping rate and the tax rate" do
            shipping_rates = subject.shipping_rates(package)
            expect(shipping_rates.first.tax_rate).to eq(tax_rate)
          end
        end
      end
    end
  end
end
