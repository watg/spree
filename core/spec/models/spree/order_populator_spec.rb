require 'spec_helper'

describe Spree::OrderPopulator do

  let(:order) { double('Order') }
  subject { Spree::OrderPopulator.new(order, "USD") }

  let(:variant) { create(:variant, price: 60.00) }
  let(:product) { variant.product }
  let(:target_id) { 45 }

  before do
    allow(order).to receive(:line_items).and_return([])
    order.should_receive(:contents).at_least(:once).and_return(Spree::OrderContents.new(self))
  end

  context "with products parameters" do
    it "can take a list of products and add them to the order" do
      order.contents.should_receive(:add).with(variant, 1, subject.currency, nil, [], [], target_id).and_return double.as_null_object
      subject.populate(:products => { product.id => variant.id }, :quantity => 1, :target_id => 45)
    end

    context "can take a list of products and options" do
      let(:selected_variant) { create(:variant) }
      let(:part_id) { "23" }

      it "of assembly definition type" do
        variant.assembly_definition = Spree::AssemblyDefinition.new
        allow(Spree::OrderPopulator).to receive(:parse_options).with(variant, { part_id => selected_variant.id }, 'USD').and_return([[selected_variant, 3, false, part_id]])
        
        order.contents.should_receive(:add).with(variant, 1, subject.currency, nil, [[selected_variant, 3, false, part_id]], [], target_id).and_return double.as_null_object
        subject.populate(:products => { product.id => variant.id, :options => { part_id => selected_variant.id } }, :quantity => 1, :target_id => 45)
      end

      it "of simple type" do
        required_part1 = create(:part)
        required_part2 = create(:part)
        part1 = create(:part)
        part2 = create(:part)
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
        order.contents.should_receive(:add).with(variant, 1, subject.currency, nil, match_array(expected_parts), [], target_id).and_return double.as_null_object
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
        order.contents.should_receive(:add).with(variant, 1, subject.currency, nil, [], personalisation_params, target_id).and_return double.as_null_object
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
      order.contents.should_not_receive(:add)
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
      order.contents.should_not_receive(:add)
      subject.populate(:products => { product.id => variant.id }, :quantity => 2_147_483_648)
      subject.should_not be_valid
      output = "Please enter a reasonable quantity."
      subject.errors.full_messages.join("").should == output
    end
  end

  context "with variant parameters" do
    it "can take a list of variants with quantites and add them to the order" do
      order.contents.should_receive(:add).with(variant, 5, subject.currency, nil, [], [], nil).and_return double.as_null_object
      subject.populate(:variants => { variant.id => 5 })
    end
  end

end
