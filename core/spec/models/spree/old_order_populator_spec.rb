require 'spec_helper'

describe Spree::OldOrderPopulator, :type => :model do

  let(:order) { mock_model(Spree::Order, currency: 'USD') }
  subject { Spree::OldOrderPopulator.new(order, "USD") }

  let(:variant) { create(:variant, amount: 60.00) }
  let(:product) { variant.product }
  let(:target_id) { 45 }

  context "#populate" do

    before do
      allow(order).to receive(:line_items).and_return([])
      expect(order).to receive(:contents).at_least(:once).and_return(Spree::OrderContents.new(order))
      allow(subject.options_parser).to receive(:missing_parts).and_return({})
    end

    context "with variants parameters" do

      let!(:options) { {
        target_id: target_id,
        suite_tab_id: 2,
        suite_id: 1,
        parts: []
      }}

      it "can take a list of products and add them to the order" do
        expect(order.contents).to receive(:add).with(variant, 2, options).and_return double.as_null_object
        subject.populate(:variants => { variant.id => 2 }, :target_id => 45, :suite_id => 1, :suite_tab_id => 2)
      end

      context "with parts" do

        let!(:lip1) { mock_model(Spree::LineItemPart) }
        let!(:lip2) { mock_model(Spree::LineItemPart) }

        let!(:adp1) { mock_model(Spree::ProductPart) }
        let!(:adp2) { mock_model(Spree::ProductPart) }
        let!(:adv1) { mock_model(Spree::ProductPartVariant) }
        let!(:adv2) { mock_model(Spree::ProductPartVariant) }

        before do
          options[:parts] = match_array [lip1, lip2]
          allow(subject.options_parser).to receive(:missing_parts).and_return({})
        end

        it "calls order contents correctly" do
          expect(order.contents).to receive(:add).with(variant, 2, options).and_return double.as_null_object
          part_params = {adp1.id => adv1.id, adp2.id => adv2.id}
          expect(subject.options_parser).to receive(:dynamic_kit_parts).with(variant, part_params).and_return [lip1, lip2]
          subject.populate(:variants => { variant.id => 2 }, :parts => part_params, :target_id => 45, :suite_id => 1, :suite_tab_id => 2)
        end


        context "missing_parts" do
          let(:part) { mock_model(Spree::ProductPart)}

          before do
            allow(subject.options_parser).to receive(:missing_parts).and_return({part.id => variant.id})
          end

          it "adds error on order when some assembly definition parts are missing" do
            expect(order.contents).to_not receive(:add)
            part_params = {adp1.id => adv1.id, adp2.id => adv2.id}
            subject.populate(:variants => { variant.id => 2 }, :parts => part_params, :target_id => 45, :suite_id => 1, :suite_tab_id => 2)
            expect(subject.errors.full_messages.join("")).to eq 'Some required parts are missing'
          end

          it "sends an airbrake notification" do
            expect(order.contents).to_not receive(:add)
            part_params = {adp1.id => adv1.id, adp2.id => adv2.id}
            notifier = double
            notification_params = {
              :target_id           => options[:target_id],
              :suite_id     => options[:suite_id],
              :suite_tab_id => options[:suite_tab_id],
              :order_id            => order.id,
              :parts               => part_params,
              :missing_parts_and_variants => {part.id => variant.id},
            }
            #expect(notifier).to receive(:notify).with("Some required parts are missing", notification_params)
            #expect(Helpers::AirbrakeNotifier).to receive(:delay).and_return(notifier)
            #Comment out the below and uncomment the above if we want to get this working async
            expect(Helpers::AirbrakeNotifier).to receive(:notify).with("Some required parts are missing", notification_params)
            subject.populate(:variants => { variant.id => 2 }, :parts => part_params, :target_id => 45, :suite_id => 1, :suite_tab_id => 2)
          end
        end
      end

    end

    context "with products parameters" do

      let!(:options) { {
        personalisations: [],
        target_id: target_id,
        suite_tab_id: 2,
        suite_id: 1,
        parts: []
      }}

      it "can take a list of products and add them to the order" do
        expect(order.contents).to receive(:add).with(variant, 1, options).and_return double.as_null_object
        subject.populate(:products => { product.id => variant.id }, :quantity => 1, :target_id => 45, :suite_id => 1, :suite_tab_id => 2)
      end

      context "with required_parts" do

        let!(:lip1) { mock_model(Spree::LineItemPart) }
        let!(:lip2) { mock_model(Spree::LineItemPart) }

        before do
          options[:parts] = match_array [lip1, lip2]
        end

        it "calls order contents correctly" do
          expect(order.contents).to receive(:add).with(variant, 1, options).and_return double.as_null_object
          expect(subject.options_parser).to receive(:static_kit_required_parts).with(variant).and_return [lip1, lip2]
          expect(subject.options_parser).to receive(:static_kit_optional_parts).with(variant,[]).and_return []
          subject.populate(:products => { product.id => variant.id, :options => [] }, :quantity => 1, :target_id => 45, :suite_id => 1, :suite_tab_id => 2)
        end

      end

      context "with optional_parts" do

        let!(:lip1) { mock_model(Spree::LineItemPart) }
        let!(:lip2) { mock_model(Spree::LineItemPart) }

        let!(:variant1) { mock_model(Spree::Variant) }
        let!(:variant2) { mock_model(Spree::Variant) }

        before do
          options[:parts] = match_array [lip1, lip2]
        end

        it "calls order contents correctly" do
          expect(order.contents).to receive(:add).with(variant, 1, options).and_return double.as_null_object
          expect(subject.options_parser).to receive(:static_kit_required_parts).with(variant).and_return []
          expect(subject.options_parser).to receive(:static_kit_optional_parts).with(variant,[variant1.id, variant2.id]).and_return [lip1, lip2]
          subject.populate(:products => { product.id => variant.id, :options => [variant1.id, variant2.id] }, :quantity => 1, :target_id => 45, :suite_id => 1, :suite_tab_id => 2)
        end

      end

      context "with personalisations" do

        let!(:personalisation) { mock_model(Spree::LineItemPersonalisation) }
        let(:monogram) { create(:personalisation_monogram, product: product) }

        before do
          options[:personalisations] = match_array [personalisation]
        end

        it "calls order contents correctly" do
          expected_params = {
            :enabled_pp_ids=>[monogram.id], 
            :pp_ids=>{
              monogram.id=>{
                "colour"=>monogram.colours.first.id,
                "initials"=>"XXX"
              }
            }
          }
          expect(subject.options_parser).to receive(:personalisations).with(expected_params).and_return [personalisation]
          expect(order.contents).to receive(:add).with(variant, 1, options).and_return double.as_null_object

          subject.populate(:products => {
            product.id => variant.id,
            enabled_pp_ids: [monogram.id],
            pp_ids: { monogram.id => {
              "colour" => monogram.colours.first.id,
              "initials" => "XXX"}}
          }, 
          :suite_tab_id=>2,
          :suite_id=>1,
          :quantity => 1, :target_id => 45)
        end

      end

      context "variant out of stock" do
        before do
          line_item = double("LineItem", valid?: false)
          allow(line_item).to receive(:errors).and_return [double]
          allow(line_item).to receive_message_chain(:errors, messages: { quantity: ["error message"] })
          allow(order.contents).to receive_messages(add: line_item)
        end

        it "adds an error when trying to populate" do
          subject.populate(:products => { product.id => variant.id }, :quantity => 1)
          expect(subject).not_to be_valid
          expect(subject.errors.full_messages.join).to eql "error message"
        end
      end

      context "products params" do
        # Regression test for #2695
        it "restricts quantities to reasonable sizes (less than 2.1 billion, seriously)" do
          expect(order.contents).to_not receive(:add)
          subject.populate(:products => { product.id => variant.id }, :quantity => 2_147_483_648)
          expect(subject).not_to be_valid
          output = "Please enter a reasonable quantity."
          expect(subject.errors.full_messages.join("")).to eq(output)
        end

        it "does not add any products if a quantity is set to 0" do
          expect(order.contents).to_not receive(:add)
          subject.populate(:products => { product.id => variant.id }, :quantity => 0)
        end


      end

      context "variants params" do
        it "restricts quantities to reasonable sizes (less than 2.1 billion, seriously)" do
          expect(order.contents).to_not receive(:add)
          subject.populate(:variants => {variant.id => 2_147_483_648 } )
          expect(subject).not_to be_valid
          output = "Please enter a reasonable quantity."
          expect(subject.errors.full_messages.join("")).to eq(output)
        end

        it "does not add any products if a quantity is set to 0" do
          expect(order.contents).to_not receive(:add)
          subject.populate(:variants => {variant.id => 0 } )
        end
      end

    end

  end

  describe "#item" do

    it "should return nil if populate has not been called succesfully" do
      expect(subject.item).to be_nil
    end


    context "item has been added to cart" do

      let(:variant) { Spree::Variant.new }
      let(:quantity) { 2 }

      before do
        allow(order).to receive(:line_items).and_return([])
        expect(order).to receive(:contents).at_least(:once).and_return(Spree::OrderContents.new(order))
        line_item = double(:line_item, errors: [])
        expect(order.contents).to receive(:add).and_return(line_item)
        subject.attempt_cart_add(variant, quantity, {})
      end

      it "should return an Item Struct with variant and quantity" do
        expect(subject.item.variant).to eq variant
        expect(subject.item.quantity).to eq quantity
      end

    end

  end


end
