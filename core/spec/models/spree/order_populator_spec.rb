require 'spec_helper'

describe Spree::OrderPopulator do

  let(:order) { mock_model(Spree::Order, currency: 'USD') }
  subject { Spree::OrderPopulator.new(order, "USD") }

  let(:variant) { create(:variant, amount: 60.00) }
  let(:product) { variant.product }
  let(:target_id) { 45 }


  context "#populate" do

    before do
      allow(order).to receive(:line_items).and_return([])
      order.should_receive(:contents).at_least(:once).and_return(Spree::OrderContents.new(order))
    end

    context "with variants parameters" do

      let!(:options) { {
        target_id: target_id,
        product_page_tab_id: 2,
        product_page_id: 1,
        parts: []
      }}

      it "can take a list of products and add them to the order" do
        expect(order.contents).to receive(:add).with(variant, 2, options).and_return double.as_null_object
        subject.populate(:variants => { variant.id => 2 }, :target_id => 45, :product_page_id => 1, :product_page_tab_id => 2)
      end

      context "with parts" do

        let!(:lip1) { mock_model(Spree::LineItemPart) }
        let!(:lip2) { mock_model(Spree::LineItemPart) }

        let!(:adp1) { mock_model(Spree::AssemblyDefinitionPart) }
        let!(:adp2) { mock_model(Spree::AssemblyDefinitionPart) }
        let!(:adv1) { mock_model(Spree::AssemblyDefinitionVariant) }
        let!(:adv2) { mock_model(Spree::AssemblyDefinitionVariant) }

        before do
          options[:parts] = match_array [lip1, lip2]
          allow(subject.options_parser).to receive(:missing_required_parts).and_return([])
        end

        it "calls order contents correctly" do
          expect(order.contents).to receive(:add).with(variant, 2, options).and_return double.as_null_object
          part_params = {adp1.id => adv1.id, adp2.id => adv2.id}
          expect(subject.options_parser).to receive(:dynamic_kit_parts).with(variant, part_params).and_return [lip1, lip2]
          subject.populate(:variants => { variant.id => 2 }, :parts => part_params, :target_id => 45, :product_page_id => 1, :product_page_tab_id => 2)
        end


        context "missing_required_parts" do
          let(:part) { mock_model(Spree::AssemblyDefinitionPart)}

          before do
            allow(subject.options_parser).to receive(:missing_required_parts).and_return([part])
          end

          it "adds error on order when some assembly definition parts are missing" do
            expect(order.contents).to_not receive(:add)
            part_params = {adp1.id => adv1.id, adp2.id => adv2.id}
            subject.populate(:variants => { variant.id => 2 }, :parts => part_params, :target_id => 45, :product_page_id => 1, :product_page_tab_id => 2)
            expect(subject.errors.full_messages.join("")).to eq 'Some required parts are missing'
          end
        end
      end

    end

    context "with products parameters" do

      let!(:options) { {
        personalisations: [],
        target_id: target_id,
        product_page_tab_id: 2,
        product_page_id: 1,
        parts: []
      }}

      it "can take a list of products and add them to the order" do
        expect(order.contents).to receive(:add).with(variant, 1, options).and_return double.as_null_object
        subject.populate(:products => { product.id => variant.id }, :quantity => 1, :target_id => 45, :product_page_id => 1, :product_page_tab_id => 2)
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
          subject.populate(:products => { product.id => variant.id, :options => [] }, :quantity => 1, :target_id => 45, :product_page_id => 1, :product_page_tab_id => 2)
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
          subject.populate(:products => { product.id => variant.id, :options => [variant1.id, variant2.id] }, :quantity => 1, :target_id => 45, :product_page_id => 1, :product_page_tab_id => 2)
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
          :product_page_tab_id=>2, 
          :product_page_id=>1,
          :quantity => 1, :target_id => 45)
        end

      end

      context "variant out of stock" do
        before do
          line_item = double("LineItem", valid?: false)
          line_item.stub(:errors).and_return [double]
          line_item.stub_chain(:errors, messages: { quantity: ["error message"] })
          order.contents.stub(add: line_item)
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
          subject.should_not be_valid
          output = "Please enter a reasonable quantity."
          subject.errors.full_messages.join("").should == output
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
          subject.should_not be_valid
          output = "Please enter a reasonable quantity."
          subject.errors.full_messages.join("").should == output
        end

        it "does not add any products if a quantity is set to 0" do
          expect(order.contents).to_not receive(:add)
          subject.populate(:variants => {variant.id => 0 } )
        end
      end

    end

  end
end
