require "spec_helper"

describe Spree::OrderPopulator, type: :model do
  let(:order) { mock_model(Spree::Order, currency: "USD") }
  subject { described_class.new(order, params) }

  let(:variant) { create(:variant, amount: 60.00) }
  let(:product) { variant.product }
  let(:target_id) { 45 }
  let(:params) {}

  let!(:order_contents_options) do
    {
      target_id: target_id,
      suite_tab_id: 2,
      suite_id: 1
    }
  end

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

  context "#populate" do
    before do
      allow(order).to receive(:line_items).and_return(order_contents_options)
      order_contents = Spree::OrderContents.new(order)
      expect(order).to receive(:contents).at_least(:once).and_return(order_contents)
      allow(subject.options_parser).to receive(:missing_parts).and_return({})
    end

    context "variant no parts" do
      it "calls order contents correctly" do
        expect(order.contents).to receive(:add).with(variant, 2, order_contents_options)
          .and_return double.as_null_object
        item = subject.populate
        expect(item.variant).to eq variant
        expect(item.quantity).to eq quantity
      end
    end

    context "variant with parts" do
      let!(:lip1) { mock_model(Spree::LineItemPart, quantity: 1) }
      let!(:lip2) { mock_model(Spree::LineItemPart, quantity: 2) }

      let!(:adp1) { mock_model(Spree::ProductPart, quantity: 1) }
      let!(:adp2) { mock_model(Spree::ProductPart, quantity: 2) }
      let!(:adv1) { mock_model(Spree::ProductPartVariant) }
      let!(:adv2) { mock_model(Spree::ProductPartVariant) }
      let(:part_params) { { adp1.id => adv1.id, adp2.id => adv2.id } }
      let(:options) { { parts: part_params } }

      it "calls order contents correctly" do
        order_contents_options.merge!(parts: match_array([lip1, lip2]))

        expect(order.contents).to receive(:add).with(variant, 2, order_contents_options)
          .and_return double.as_null_object

        expect(subject.options_parser).to receive(:dynamic_kit_parts).with(variant, part_params)
          .and_return [lip1, lip2]

        item = subject.populate
        expect(item.variant).to eq variant
        expect(item.quantity).to eq quantity
      end

      context "missing parts" do
        let(:part) { mock_model(Spree::ProductPart) }
        let(:missing_parts) { { part.id => variant.id } }
        let(:error) { "Some required parts are missing: #{missing_parts}" }
        let(:notify_params) { params.merge(order_id: order.id) }

        before do
          allow(subject.options_parser).to receive(:missing_parts).and_return(missing_parts)
        end

        it "sends a notication if parts are missing" do
          expect(order.contents).to_not receive(:add)
          expect(Helpers::AirbrakeNotifier).to receive(:notify).with(error, notify_params)
          item = subject.populate
          expect(item.variant).to eq variant
          expect(item.quantity).to eq quantity
        end
      end
    end

    context "variant with static parts" do
      let!(:static_part) { create(:base_variant) }
      let!(:optional_static_part) { create(:base_variant) }

      let(:part_params) { [optional_static_part] }
      let(:options) { { optional_static_parts: part_params } }

      before do
        variant.add_part(static_part, 1, false)
        product.add_part(optional_static_part, 2, true)
      end

      it "calls order contents correctly" do
        matcher_1 = have_attributes(quantity: 1, optional: false, variant: static_part)
        matcher_2 = have_attributes(quantity: 2, optional: true, variant: optional_static_part)
        order_contents_options.merge!(parts: match_array([matcher_1, matcher_2]))

        expect(order.contents).to receive(:add).with(variant, 2, order_contents_options)
          .and_return double.as_null_object

        item = subject.populate
        expect(item.variant).to eq variant
        expect(item.quantity).to eq quantity
      end
    end

    context "variant with personalisations" do
      let!(:personalisation) { mock_model(Spree::LineItemPersonalisation) }
      let(:monogram) { create(:personalisation_monogram, product: product) }
      let(:enabled) { true }

      let(:personalisation_params) do
        [
          {
            id: monogram.id,
            enabled: enabled,
            data: {
              "colour" => monogram.colours.first.id,
              "initials" => "XXX"
            }
          }
        ]
      end

      let(:options) { { personalisations: personalisation_params } }

      it "calls order contents correctly" do
        attributes = {
          personalisation_id: monogram.id,
          amount: BigDecimal.new(10),
          data: { "colour" => monogram.colours.first.id.to_s, "initials" => "XXX" }
        }
        matcher = have_attributes(attributes)
        order_contents_options.merge!(personalisations: match_array([matcher]))

        expect(order.contents).to receive(:add).with(variant, 2, order_contents_options)
          .and_return double.as_null_object

        item = subject.populate
        expect(item.variant).to eq variant
        expect(item.quantity).to eq quantity
      end

      context "disabled personalisation" do
        let(:enabled) { false }

        it "calls order contents correctly" do
          expect(order.contents).to receive(:add).with(variant, 2, order_contents_options)
            .and_return double.as_null_object

          item = subject.populate
          expect(item.variant).to eq variant
          expect(item.quantity).to eq quantity
        end
      end
    end
  end

  context "#populate with errors" do
    context "quantity to low" do
      let(:quantity) { 0 }
      it "returns a error" do
        item = subject.populate
        expect(item).to_not be_nil
        output = "Please enter a reasonable quantity."
        expect(item.errors).to eq([output])
      end
    end

    context "quantity to high" do
      let(:quantity) { 100_000_000_000_000_000 }
      it "returns a error" do
        item = subject.populate
        expect(item).to_not be_nil
        output = "Please enter a reasonable quantity."
        expect(item.errors).to eq([output])
      end
    end

    context "variant out of stock" do
      before do
        order_contents = Spree::OrderContents.new(order)
        expect(order).to receive(:contents).at_least(:once).and_return(order_contents)
        line_item = double("LineItem", valid?: false)
        allow(line_item).to receive(:errors).and_return [double]
        error_message = { quantity: ["error message"] }
        allow(line_item).to receive_message_chain(:errors, messages: error_message)
        allow(order.contents).to receive_messages(add: line_item)
      end

      it "adds an error when trying to populate" do
        item = subject.populate
        expect(item).to_not be_nil
        expect(item.errors).to eql ["error message"]
      end
    end
  end
end
