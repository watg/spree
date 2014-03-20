require 'spec_helper'

describe Spree::OrderPopulator do

  let(:order) { double('Order') }
  subject { Spree::OrderPopulator.new(order, "USD") }

  context "without assembly_definition" do
    let(:variant) { create(:variant, price: 60.00) }
    let(:product) { variant.product }
    let(:target_id) { 45 }

    before do
      order.should_receive(:contents).at_least(:once).and_return(Spree::OrderContents.new(self))
    end

    context "with products parameters" do
      it "can take a list of products and add them to the order" do
        order.contents.should_receive(:add).with(variant, 1, subject.currency, nil, [], [], target_id).and_return double.as_null_object
        subject.populate(:products => { variant.product.id => variant.id }, :quantity => 1, :target_id => 45)
      end

      it "can take a list of products with options and add them to the order" do
        part1 = create(:part)
        part2 = create(:part)
        product.add_part(part1, 1, true)
        product.add_part(part2, 2, true)
        order.contents.should_receive(:add).with(variant, 1, subject.currency, nil, [ [part2, 2], [part1, 1] ], [], target_id).and_return double.as_null_object
        subject.populate(:products => { variant.product.id => variant.id, :options => [part1.id, part2.id] }, :quantity => 1, :target_id => 45)
      end

      it "does not add any products if a quantity is set to 0" do
        order.contents.should_not_receive(:add)
        subject.populate(:products => { variant.product.id => variant.id }, :quantity => 0)
      end

      context "variant out of stock" do
        before do
          line_item = double("LineItem", valid?: false)
          line_item.stub_chain(:errors, messages: { quantity: ["error message"] })
          order.contents.stub(add: line_item)
        end

        it "adds an error when trying to populate" do
          subject.populate(:products => { variant.product.id => variant.id }, :quantity => 1)
          expect(subject).not_to be_valid
          expect(subject.errors.full_messages.join).to eql "error message"
        end
      end

      # Regression test for #2695
      it "restricts quantities to reasonable sizes (less than 2.1 billion, seriously)" do
        order.contents.should_not_receive(:add)
        subject.populate(:products => { variant.product.id => variant.id }, :quantity => 2_147_483_648)
        subject.should_not be_valid
        output = "Please enter a reasonable quantity."
        subject.errors.full_messages.join("").should == output
      end
    end

    context "with variant parameters" do
      it "can take a list of variants with quantites and add them to the order" do
        order.contents.should_receive(:add).with(variant, 5, subject.currency, nil, [], nil, nil).and_return double.as_null_object
        subject.populate(:variants => { variant.id => 5 })
      end
    end
  end


  context "with assembly definition" do
    let(:variant) { create(:variant, price: 60.00) }
    let(:product) { variant.product }
    let(:target_id) { 45 }

    before do
      order.should_receive(:contents).at_least(:once).and_return(Spree::OrderContents.new(self))
    end

  end
end
