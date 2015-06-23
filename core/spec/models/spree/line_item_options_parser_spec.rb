require 'spec_helper'

describe Spree::LineItemOptionsParser do

  subject { described_class.new("USD") }

  let!(:variant) { create(:variant) }
  let!(:product) { variant.product }
  let(:target_id) { 45 }

  context "#personalisations" do

    let(:monogram) { create(:personalisation_monogram, product: product) }
    let(:expected_personalisations) { [
      Spree::LineItemPersonalisation.new(
        personalisation_id: monogram.id,
        line_item_id: nil,
        amount: BigDecimal.new('10.0'),
        data: { "colour" => monogram.colours.first.id, "initials"=>"XXX" },
        created_at: nil,
        updated_at: nil)
    ] }

    it "calls order contents correctly" do
      params = {
        enabled_pp_ids: [monogram.id],
        pp_ids: {
          monogram.id=>{
            "colour"=>monogram.colours.first.id,
            "initials"=>"XXX"
          }
        }
      }

      personalisations = subject.personalisations(params)
      expect(personalisations.map(&:attributes)).to match_array expected_personalisations.map(&:attributes)
    end

  end

  context "#parts" do
    context "dynamic kits" do
      let!(:variant_assembly) { create(:variant) }
      let!(:assem_def) { create(:assembly_definition, variant: variant_assembly) }
      let!(:variant_part)  { create(:base_variant, product: product, prices: [price]) }
      let!(:price) { create(:price, price: 2.99, sale: false, is_kit: true, price_type: "part", currency: 'USD') }
      let!(:adp) do
        create(:assembly_definition_part,
               assembly_definition: assem_def,
               part_product: product,
               count: 2)
      end
      let!(:adv) { create(:assembly_definition_variant, assembly_definition_part: adp, variant: variant_part) }

      let(:expected_parts) { [
        Spree::LineItemPart.new(
          assembly_definition_part_id: adp.id,
          variant_id: variant_part.id,
          quantity: adp.count,
          optional: adp.optional,
          price: price.amount,
          currency: "USD",
          container: false
        ) ] }

      it "can parse parts from the options" do
        parts = subject.dynamic_kit_parts(variant_assembly.reload, adp.id.to_s => variant_part.id)
        expect(parts.map(&:attributes)).to match_array expected_parts.map(&:attributes)
      end

      context "Setting the main part" do

        let(:expected_parts) { [
          Spree::LineItemPart.new(
            assembly_definition_part_id: adp.id,
            variant_id: variant_part.id,
            quantity: 2,
            optional: adp.optional,
            price: price.amount,
            currency: "USD",
            container: false
          )
        ] }

        before do
          adp.optional = true
          adp.save
          assem_def.reload
          assem_def.save
        end

        context "non required part" do
          it "creates the correct params" do
            parts = subject.dynamic_kit_parts(variant_assembly, {adp.id.to_s => variant_part.id})
            expect(parts.map(&:attributes)).to match_array expected_parts.map(&:attributes)
          end
        end

        context "required part" do

          before do
            adp.optional = false
            adp.save
          end

          it "creates the correct params" do
            parts = subject.dynamic_kit_parts(variant_assembly.reload,
                                              adp.id.to_s => variant_part.id)
            expect(parts.map(&:attributes)).to match_array expected_parts.map(&:attributes)
          end

        end
      end

      context "valid params" do

        let(:bogus_variant_assembly) { create(:variant) }
        let(:bogus_ad) { create(:assembly_definition, variant: bogus_variant_assembly) }
        let(:bogus_product_part)  { create(:base_product) }
        let(:bogus_variant_part)  { create(:base_variant, product: bogus_product_part) }
        let(:bogus_adp) { create(:assembly_definition_part, bogus_adp_opts) }
        let(:bogus_adp_opts) { { assembly_definition: bogus_ad, part_product: bogus_product_part } }
        let(:bogus_adv) { create(:assembly_definition_variant, assembly_definition_part: bogus_adp, variant: bogus_variant_part) }

        it "assembly variant must be valid" do
          expect do
            subject.dynamic_kit_parts(variant_assembly, {bogus_adp.id.to_s => variant_part.id})
          end.to raise_error
        end

        it "parts must be valid" do
          expect do
            subject.dynamic_kit_parts(variant_assembly, {bogus_adp.id.to_s => variant_part.id})
          end.to raise_error
        end

        # create a variant based off the correct part, but do not create a assembly_definition_variant, hence it should not be allowed
        let(:another_bogus_variant_part)  { create(:base_variant, product: product) }

        it "selected variant must be valid" do
          expect do
            subject.dynamic_kit_parts(variant_assembly, {adp.id.to_s => another_bogus_variant_part.id.to_s})
          end.to raise_error
        end

        it "selected variant can not be nil" do
          expect do
            subject.dynamic_kit_parts(variant_assembly, {adp.id.to_s => ""})
          end.to raise_error
        end

        it "selected variant " do
          parts = subject.dynamic_kit_parts(variant_assembly, {adp.id.to_s => Spree::AssemblyDefinitionPart::NO_THANKS})
          expect(parts).to match_array []
        end

        context "#missing_parts" do

          it "returns empty hash if all parts are present" do
            outcome = subject.missing_parts(variant_assembly.reload, adp.id.to_s => variant_part.id)
            expect(outcome).to eq Hash.new
          end

          it "returns parts that are bogus" do
            outcome = subject.missing_parts(variant_assembly, {bogus_adp.id.to_s => variant_part.id})
            expected = { bogus_adp.id.to_s => variant_part.id }
            expect(outcome).to eq expected
          end

          it "returns parts missing their variant" do
            outcome = subject.missing_parts(variant_assembly, {bogus_adp.id.to_s => "" })
            expected = { bogus_adp.id.to_s => "" }
            expect(outcome).to eq expected
          end

          it "returns no missing parts if the value is set to no_thanks" do
            outcome = subject.missing_parts(variant_assembly.reload,
              {adp.id.to_s => Spree::AssemblyDefinitionPart::NO_THANKS})
            expect(outcome).to eq Hash.new
          end
        end
      end

      context "when the part has parts of its own (old kit in an assembly)" do
        let(:other_product)  { create(:base_product) }
        let(:other_variant)  { create(:base_variant, product: other_product) }
        let(:other_part) { create(:assembly_definition_part, op_opts) }
        let(:op_opts)  { { assembly_definition: assem_def, part_product: other_product, count: 1 } }
        let!(:other_part_variant) { create(:assembly_definition_variant, assembly_definition_part: other_part, variant: other_variant) }

        # Override the price to 0 as this is now a container
        let(:part_attached_to_product) { create(:base_variant, prices: [part_product_price]) }
        let(:part_attached_to_variant) { create(:base_variant, prices: [part_variant_price]) }
        let!(:part_product_price) { create(:price, part_amount: 1.99, sale: false, is_kit: true, currency: 'USD') }
        let!(:part_variant_price) { create(:price, part_amount: 3.99, sale: false, is_kit: true, currency: 'USD') }

        before do
          variant_part.product.add_part(part_attached_to_product, 3, false)
          variant_part.add_part(part_attached_to_variant, 4, false)
        end

        it "adds the container and its parts to the parts table and flags the container" do

          # The container part which will be used for the old kit
          lip1 = Spree::LineItemPart.new(
            assembly_definition_part_id: adp.id,
            variant_id: variant_part.id,
            quantity: 2,
            optional: adp.optional,
            price: price.part_amount,
            currency: "USD",
            container: true)

          lip2 = Spree::LineItemPart.new(
            assembly_definition_part_id: other_part.id,
            variant_id: other_variant.id,
            quantity: 1,
            optional: false,
            price: BigDecimal.new('0.00'),
            currency: "USD",
            container: false)

          lip3 = Spree::LineItemPart.new(
            assembly_definition_part_id: adp.id,
            variant_id: part_attached_to_product.id,
            quantity: 6,
            optional: adp.optional,
            price: part_product_price.part_amount,
            currency: "USD",
            parent_part: lip1, # the id refers to the parent container index
            container: false)

          lip4 = Spree::LineItemPart.new(
            assembly_definition_part_id: adp.id,
            variant_id: part_attached_to_variant.id,
            quantity: 8,
            optional: adp.optional,
            price: part_variant_price.part_amount,
            currency: "USD",
            parent_part: lip1, # the id refers to the parent container index
            container: false)

          parts = subject.dynamic_kit_parts(variant_assembly.reload,
                                            adp.id.to_s =>        variant_part.id.to_s,
                                            other_part.id.to_s => other_variant.id.to_s)
          expect(parts.map(&:attributes)).to match_array [lip1,lip2,lip3,lip4].map(&:attributes)
        end
      end

    end

    context "static kits" do

      let(:required_part1) { create(:variant, prices: [required_part1_price]) }
      let(:part1) { create(:variant, prices: [part1_price]) }
      let!(:required_part1_price) { create(:price, price: 1.99, sale: false, is_kit: true, price_type: "part", currency: 'USD') }
      let!(:part1_price) { create(:price, price: 3.99, sale: false, is_kit: true, price_type: "part", currency: 'USD') }

      let(:expected_required_parts) { [
        Spree::LineItemPart.new(
          assembly_definition_part_id: nil,
          variant_id: required_part1.id,
          quantity: 2,
          optional: false,
          price: required_part1_price.part_amount,
          currency: "USD",
          container: false
        ) ] }

      let(:expected_optional_parts) { [
        Spree::LineItemPart.new(
          assembly_definition_part_id: nil,
          variant_id: part1.id,
          quantity: 1,
          optional: true,
          price: part1_price.part_amount,
          currency: "USD",
          container: false
        )
      ] }

      before do
        product.add_part(part1, 1, true)
        product.add_part(required_part1, 2, false)
      end

      it "can parse part from the required parts for old style kit" do
        parts = subject.static_kit_required_parts(variant)
        expect(parts.map(&:attributes)).to match_array expected_required_parts.map(&:attributes)
      end

      it "can parse part from the optional parts for old style kit" do
        parts = subject.static_kit_optional_parts(variant,[part1.id])
        expect(parts.map(&:attributes)).to match_array expected_optional_parts.map(&:attributes)
      end

    end

    context "#part_price_amount" do
      let(:price) { mock_model(Spree::Price, amount: 1)}
      let(:nil_price) { mock_model(Spree::Price, amount: nil)}

      context "variant price_part_in available" do

        before do
          allow(variant).to receive(:price_part_in).with('USD').and_return(price)
        end

        it "returns a price" do
          expect(subject.send(:part_price_amount, variant)).to eq price.amount
        end
      end

      context "variant price_part_in not available but master price_part_in is" do

        before do
          allow(variant).to receive(:price_part_in).with('USD').and_return(nil_price)
          allow(product.master).to receive(:price_part_in).with('USD').and_return(price)
        end


        it "returns a price" do
          expect(subject.send(:part_price_amount, variant)).to eq price.amount
        end
      end

      context "variant master price_part_in not available but price_normal_in is" do

        before do
          allow(variant).to receive(:price_part_in).with('USD').and_return(nil_price)
          allow(product.master).to receive(:price_part_in).with('USD').and_return(nil_price)
          allow(variant).to receive(:price_normal_in).with('USD').and_return(price)
          #allow(product.master).to receive(price_normal_in).with('USD').and_return(nil_price)
        end


        it "returns a price" do
          expect(subject.send(:part_price_amount, variant)).to eq price.amount
        end
      end

      context "variant price_normal_in not available but master price_normal_in is" do

        before do
          allow(variant).to receive(:price_part_in).with('USD').and_return(nil_price)
          allow(product.master).to receive(:price_part_in).with('USD').and_return(nil_price)
          allow(variant).to receive(:price_normal_in).with('USD').and_return(nil_price)
          allow(product.master).to receive(:price_normal_in).with('USD').and_return(price)
        end

        it "returns a price" do
          expect(subject.send(:part_price_amount, variant)).to eq price.amount
        end
      end
    end
  end
end
