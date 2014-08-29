require 'spec_helper'

describe Spree::OrderPopulator do

  let(:order) { double('Order') }
  subject { Spree::OrderPopulator.new(order, "USD") }

  let(:variant) { create(:variant, price: 60.00) }
  let(:product) { variant.product }
  let(:target_id) { 45 }

  context "#parse_options" do

    context "new kit" do

      let!(:variant_assembly) { create(:variant) }
      let!(:assembly_definition) { create(:assembly_definition, variant: variant_assembly) }
      let!(:variant_part)  { create(:base_variant, product: product) }
      let!(:price) { create(:price, variant: variant_part, price: 2.99, sale: false, is_kit: true, currency: 'USD') }
      let!(:adp) { create(:assembly_definition_part, assembly_definition: assembly_definition, product: product, count: 2, assembled: true) }
      let!(:adv) { create(:assembly_definition_variant, assembly_definition_part: adp, variant: variant_part) }


      let(:expected_parts) { [
        OpenStruct.new(
          assembly_definition_part_id: adp.id,
          variant_id: variant_part.id,
          quantity: adp.count,
          optional: adp.optional,
          price: price.amount,
          currency: "USD",
          assembled: true
        ) ] }

      it "can parse parts from the options" do
        parts = subject.class.parse_options(variant_assembly, {adp.id.to_s => variant_part.id.to_s}, 'USD')
        expect(parts).to match_array expected_parts
      end

      context "#attempt_cart_add" do
        it "adds error on order when some assembly definition parts are missing" do
          subject.send(:attempt_cart_add, variant_assembly.id, 1, [], [], nil, nil, nil)
          expect(subject.errors[:base]).to include "Some required parts are missing"
        end
      end


      context "valid params" do

        let(:bogus_variant_assembly) { create(:variant) }
        let(:bogus_assembly_definition) { create(:assembly_definition, variant: bogus_variant_assembly) }
        let(:bogus_product_part)  { create(:base_product) }
        let(:bogus_variant_part)  { create(:base_variant, product: bogus_product_part) }
        let(:bogus_adp) { create(:assembly_definition_part, assembly_definition: bogus_assembly_definition, product: bogus_product_part) }
        let(:bogus_adv) { create(:assembly_definition_variant, assembly_definition_part: bogus_adp, variant: bogus_variant_part) }

        it "assembly variant must be valid" do
          parts = subject.class.parse_options( create(:variant), {adp.id.to_s => variant_part.id.to_s}, 'USD')
          expect(parts).to match_array []
        end

        it "parts must be valid" do
          parts = subject.class.parse_options( variant_assembly, {bogus_adp.id.to_s => bogus_variant_part.id.to_s}, 'USD')
          expect(parts).to match_array []
        end

        # create a variant based off the correct part, but do not create a assembly_definition_variant, hence it should not be allowed
        let(:another_bogus_variant_part)  { create(:base_variant, product: product) }

        it "selected variant must be valid" do
          parts = subject.class.parse_options(variant_assembly, {adp.id.to_s => another_bogus_variant_part.id.to_s}, 'USD')
          expect(parts).to match_array []
        end

      end

      context "when the part has parts of its own (old kit in an assembly)" do
        let(:other_product)  { create(:base_product) }
        let(:other_variant)  { create(:base_variant, product: other_product) }
        let(:other_part) { create(:assembly_definition_part, assembly_definition: assembly_definition, product: other_product, count: 1) }
        let!(:other_part_variant) { create(:assembly_definition_variant, assembly_definition_part: other_part, variant: other_variant) }

        let(:part_attached_to_product) { create(:base_variant) }
        let(:part_attached_to_variant) { create(:base_variant) }

        before do
          variant_part.product.add_part(part_attached_to_product, 3, false)
          variant_part.add_part(part_attached_to_variant, 4, false)
        end

        let(:expected_parts) { [
          OpenStruct.new(
            assembly_definition_part_id: adp.id,
            variant_id: part_attached_to_product.id,
            quantity: 6,
            optional: adp.optional,
            price: price.amount,
            currency: "USD",
            assembled: true,
            parent_part_id: 0 # the id refers to the parent container index
          ),
          OpenStruct.new(
            assembly_definition_part_id: adp.id,
            variant_id: part_attached_to_variant.id,
            quantity: 8,
            optional: adp.optional,
            price: price.amount,
            currency: "USD",
            assembled: true,
            parent_part_id: 0 # the id refers to the parent container index
          ),
          OpenStruct.new(
            assembly_definition_part_id: adp.id,
            variant_id: variant_part.id,
            quantity: 2,
            optional: adp.optional,
            price: price.amount,
            currency: "USD",
            assembled: true,
            container: true,
            id: 0 # the id here refers to the container index
          ),
          OpenStruct.new(
            assembly_definition_part_id: other_part.id,
            variant_id: other_variant.id,
            quantity: 1,
            optional: false,
            price: nil,
            currency: "USD",
            assembled: false
          )
        ] }

        it "adds the container and its parts to the parts table and flags the container" do
          parts = subject.class.parse_options(variant_assembly, {adp.id.to_s => variant_part.id.to_s, other_part.id.to_s => other_variant.id.to_s}, 'USD')
          expect(parts).to match_array expected_parts
        end
      end

    end

    context "old kit" do

      let(:required_part1) { create(:variant) }
      let(:part1) { create(:variant) }
      let(:expected_parts) { [
        OpenStruct.new(
          assembly_definition_part_id: nil,
          variant_id: required_part1.id,
          quantity: 2,
          optional: false,
          price: nil,
          currency: "USD"
        ),
        OpenStruct.new(
          assembly_definition_part_id: nil,
          variant_id: part1.id,
          quantity: 1,
          optional: true,
          price: nil,
          currency: "USD"
        ),
      ] }

      before do
        product.add_part(part1, 1, true)
        product.add_part(required_part1, 2, false)
      end

      it "can parse part from the options for old style kit" do
        parts = subject.class.parse_options(variant, [part1], 'USD')
        expect(parts).to match_array expected_parts
      end
    end

  end


  context "#populate" do

    before do
      allow(order).to receive(:line_items).and_return([])
      order.should_receive(:contents).at_least(:once).and_return(Spree::OrderContents.new(self))
    end


    context "with products parameters" do
      it "can take a list of products and add them to the order" do
        options = {
          shipment: nil,
          personalisations: [],
          target_id: target_id,
          product_page_tab_id: nil,
          product_page_id: nil,
          parts: []
        }
        expect(order.contents).to receive(:add).with(variant, 1, subject.currency, options).and_return double.as_null_object
        subject.populate(:products => { product.id => variant.id }, :quantity => 1, :target_id => 45)
      end

      context "can take a list of products and options" do
        let(:selected_variant) { create(:variant) }
        let(:part_id) { "23" }
        let(:option_part) {
          OpenStruct.new(
            assembly_definition_part_id: part_id,
            variant_id: selected_variant.id,
            quantity: 1,
            optional: false,
            price: 12,
            currency: "USD")
        }

        it "of assembly definition type" do
          variant.assembly_definition = Spree::AssemblyDefinition.new
          allow(Spree::OrderPopulator).to receive(:parse_options).with(variant, { part_id => selected_variant.id }, 'USD').and_return([option_part])

          options = {
            shipment: nil,
            personalisations: [],
            target_id: target_id,
            product_page_tab_id: nil,
            product_page_id: nil,
            parts: [option_part]
          }
          expect(order.contents).to receive(:add).with(variant, 1, subject.currency, options).and_return double.as_null_object
          subject.populate(:products => { product.id => variant.id, :options => { part_id => selected_variant.id } }, :quantity => 1, :target_id => 45)
        end

        it "of simple type" do
          required_part1 = create(:variant)
          required_part2 = create(:variant)
          part1 = create(:variant)
          part2 = create(:variant)
          product.add_part(part1, 1, true)
          product.add_part(part2, 2, true)
          product.add_part(required_part1, 2, false)
          product.add_part(required_part2, 1, false)

          expected_parts = [
            OpenStruct.new(
              assembly_definition_part_id: nil,
              variant_id: required_part1.id,
              quantity: 2,
              optional: false,
              price: nil,
              currency: "USD"
            ),
            OpenStruct.new(
              assembly_definition_part_id: nil,
              variant_id: required_part2.id,
              quantity: 1,
              optional: false,
              price: nil,
              currency: "USD"
            ),
            OpenStruct.new(
              assembly_definition_part_id: nil,
              variant_id: part1.id,
              quantity: 1,
              optional: true,
              price: nil,
              currency: "USD"
            ),
            OpenStruct.new(
              assembly_definition_part_id: nil,
              variant_id: part2.id,
              quantity: 2,
              optional: true,
              price: nil,
              currency: "USD"
            )
          ]

          options = {
            shipment: nil,
            personalisations: [],
            target_id: target_id,
            product_page_tab_id: nil,
            product_page_id: nil,
            parts: match_array(expected_parts)
          }

          expect(order.contents).to receive(:add).with(variant, 1, subject.currency, options).and_return double.as_null_object
          outcome = subject.populate(:products => { product.id => variant.id, :options => [part1.id, part2.id] }, :quantity => 1, :target_id => 45)
          expect(outcome).to be_true
        end
      end


      context "can take a list of products and personalisations" do
        let(:monogram) { create(:personalisation_monogram, product: product) }
        let(:personalisation_params) {[
          OpenStruct.new(
                         personalisation_id: monogram.id,
                         amount: "10.0",
                         data: { 'colour' => monogram.colours.first.id, 'initials' => 'XXX'},
                        )
        ]}

        it "of simple type" do
          options = {
            shipment: nil,
            personalisations: personalisation_params,
            target_id: target_id,
            product_page_tab_id: nil,
            product_page_id: nil,
            parts: []
          }

          expect(order.contents).to receive(:add).with(variant, 1, subject.currency, options).and_return double.as_null_object

          subject.populate(:products => {
            product.id => variant.id,
            enabled_pp_ids: [monogram.id],
            pp_ids: { monogram.id => {
              "colour" => monogram.colours.first.id,
              "initials" => "XXX"}}
          }, :quantity => 1, :target_id => 45)
        end
      end


      it "does not add any products if a quantity is set to 0" do
        expect(order.contents).to_not receive(:add)
        subject.populate(:products => { product.id => variant.id }, :quantity => 0)
      end

      context "variant out of stock" do
        before do
          line_item = double("LineItem", valid?: false)
          line_item.stub_chain(:errors, messages: { quantity: ["error message"] })
          order.contents.stub(add: line_item)
        end

        it "adds an error when trying to populate" do
          subject.populate(:products => { product.id => variant.id }, :quantity => 1)
          expect(subject).not_to be_valid
          expect(subject.errors.full_messages.join).to eql "error message"
        end
      end

      # Regression test for #2695
      it "restricts quantities to reasonable sizes (less than 2.1 billion, seriously)" do
        expect(order.contents).to_not receive(:add)
        subject.populate(:products => { product.id => variant.id }, :quantity => 2_147_483_648)
        subject.should_not be_valid
        output = "Please enter a reasonable quantity."
        subject.errors.full_messages.join("").should == output
      end
    end

    context "with variant parameters" do
      it "can take a list of variants with quantites and add them to the order" do
        options = {
          shipment: nil,
          personalisations: [],
          target_id: nil,
          product_page_tab_id: nil,
          product_page_id: nil,
          parts: []
        }

        expect(order.contents).to receive(:add).with(variant, 5, subject.currency, options).and_return double.as_null_object
        subject.populate(:variants => { variant.id => 5 })
      end
    end

    context "with product_page and tab parameters" do
      it "can take a list of variants with quantites and add them to the order" do
        options = {
          shipment: nil,
          personalisations: [],
          target_id: nil,
          product_page_tab_id: 2,
          product_page_id: 1,
          parts: []
        }

        expect(order.contents).to receive(:add).with(variant, 5, subject.currency, options).and_return double.as_null_object
        subject.populate(:variants => { variant.id => 5} , :product_page_id => 1, :product_page_tab_id => 2 )
      end
    end



  end
end
