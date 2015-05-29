require 'spec_helper'

describe Spree::StockCheckJob do

  describe "variant, which is not part of any kit" do
    let(:variant_not_part) {create(:variant, in_stock_cache: true, updated_at: 1.day.ago)}
    subject { Spree::StockCheckJob.new(variant_not_part) }

    before do
      allow(subject).to receive(:rebuild_suite_tab_cache)
      allow(subject).to receive(:persist_updates)
      allow(variant_not_part).to receive(:can_supply?).and_return true
      variant_not_part.in_stock_cache = false
    end

    it "updates just the variant" do
      expect(variant_not_part.reload.in_stock_cache).to eq true
      subject.perform
    end

    it "touches the variant" do
      expect(variant_not_part.updated_at).to be_within(2.seconds).of(Time.now)
      subject.perform
    end

    it "triggers the suite_tab_cache_rebuilder" do
      expect(subject).to receive(:rebuild_suite_tab_cache).with(variant_not_part.product)
      subject.perform
    end
  end

  describe "persist_updates" do

    let(:mock_variant) { double('variant', in_stock_cache: true)}
    subject { Spree::StockCheckJob.new(mock_variant) }

    before do
      allow(subject).to receive(:adjusted_variants).and_return({mock_variant => mock_variant})
    end

    it "updates the in_stock_cache column and touch" do
      expect(mock_variant).to receive(:update_column).with(:in_stock_cache, true)
      expect(mock_variant).to receive(:touch)
      subject.send(:persist_updates)
    end
    
  end

  describe "rebuild_suite_tab_cache" do

    let(:mock_product) { double('product')}
    let(:mock_variant) { double('variant', product: mock_product)}
    subject { Spree::StockCheckJob.new(mock_variant) }

    it "calls Spree::SuiteTabCacheRebuilder with the correct arguments" do
      expect(Spree::SuiteTabCacheRebuilder).to receive(:rebuild_from_product).with(mock_product)
      subject.send(:rebuild_suite_tab_cache, mock_product)
    end

  end

  describe "force flag" do
    let(:variant_not_part) {create(:variant, in_stock_cache: true, updated_at: 1.day.ago)}
    let(:force) { false }
    subject { Spree::StockCheckJob.new(variant_not_part, force) }

    before do
      allow(subject).to receive(:rebuild_suite_tab_cache)
      allow(variant_not_part).to receive(:can_supply?).and_return true
      variant_not_part.in_stock_cache = true
    end

    it "does not update the variant if force is disabled" do
      expect(variant_not_part).to_not receive(:update_column)
      expect(variant_not_part).to_not receive(:touch)
      subject.perform
    end

    context "force enabled" do
      let(:force) { true }
      it "updates the variant" do
        expect(variant_not_part).to receive(:update_column).with(:in_stock_cache, true)
        expect(variant_not_part).to receive(:touch)
        subject.perform
      end
    end

  end

  describe "Static Kit" do
    let(:kit) {create(:base_variant, in_stock_cache: true)}
    let(:part) {create(:base_variant, in_stock_cache: true)}
    let(:another_part) {create(:base_variant, in_stock_cache: true)}
    let!(:ap) do
      Spree::StaticAssembliesPart.create(part_id: part.id, assembly_id: kit.id, assembly_type: 'Spree::Variant', count: 1, optional: false)
    end
    let!(:another_ap) do
      Spree::StaticAssembliesPart.create(part_id: another_part.id, assembly_id: kit.id, assembly_type: 'Spree::Variant', count: 1, optional: false)
    end

    before do
      allow(subject).to receive(:rebuild_suite_tab_cache)
      allow(part).to receive(:can_supply?).and_return true
      allow(another_part).to receive(:can_supply?).and_return true
    end

    describe "stock check for the the Kit itself" do
      subject { Spree::StockCheckJob.new(kit) }

      context "Kit is in stock but can supply is false" do
        before do
          allow(kit).to receive(:can_supply?).and_return false
        end

        it "in stock cache does not change" do
          # require 'pry';binding.pry
          expect(kit.reload.in_stock_cache).to be_truthy
          subject.perform
          expect(kit.reload.in_stock_cache).to be_truthy
        end

        it "triggers the suite_tab_cache_rebuilder" do
          expect(subject).to_not receive(:rebuild_suite_tab_cache).with(kit.product)
          subject.perform
        end

      end

      context "Kit is out of stock but and has missing required parts, but can supply is true" do
        let(:kit) {create(:base_variant, in_stock_cache: false)}
        let(:part) {create(:base_variant, in_stock_cache: false)}
        before do
          kit.in_stock_cache = false
          allow(kit).to receive(:can_supply?).and_return true
        end

        it "in stock cache does not change" do
          subject.perform
          expect(kit.reload.in_stock_cache).to be_falsey
        end

        it "triggers the suite_tab_cache_rebuilder" do
          expect(subject).to_not receive(:rebuild_suite_tab_cache).with(kit.product)
          subject.perform
        end

      end
    end

    context "optional parts" do

      let!(:ap) do
        Spree::StaticAssembliesPart.create(part_id: part.id, assembly_id: kit.id, assembly_type: 'Spree::Variant', count: 1, optional: true)
      end
      subject { Spree::StockCheckJob.new(part) }

      context "with optional part out of stock" do
        let(:kit) {create(:base_variant, in_stock_cache: true)}
        let(:part) {create(:base_variant, in_stock_cache: false)}
        before do
          allow(part).to receive(:can_supply?).and_return false
        end

        it "does not influence the in_stock_cache" do
          expect(kit.in_stock_cache).to be_truthy
          subject.perform
          expect(kit.reload.in_stock_cache).to be_truthy
        end

        it "does not trigger the suite_tab_cache_rebuilder" do
          expect(subject).to_not receive(:rebuild_suite_tab_cache).with(kit.product)
          subject.perform
        end
      end

      context "with optional part in stock" do
        let(:kit) {create(:base_variant, in_stock_cache: false)}
        let(:part) {create(:base_variant, in_stock_cache: true)}
        before do
          allow(part).to receive(:can_supply?).and_return true
        end

        it "does not influence the in_stock_cache" do
          expect(kit.in_stock_cache).to be_falsey
          subject.perform
          expect(kit.reload.in_stock_cache).to be_falsey
        end

        it "does not trigger the suite_tab_cache_rebuilder" do
          expect(subject).to_not receive(:rebuild_suite_tab_cache).with(kit.product)
          subject.perform
        end
      end

      context "with optional part going out of stock" do
        let(:kit) {create(:base_variant, in_stock_cache: false)}
        let(:part) {create(:base_variant, in_stock_cache: true)}
        before do
          allow(part).to receive(:can_supply?).and_return false
        end

        it "does not influence the in_stock_cache" do
          expect(kit.in_stock_cache).to be_falsey
          subject.perform
          expect(kit.reload.in_stock_cache).to be_falsey
        end

        it "does not trigger the suite_tab_cache_rebuilder" do
          expect(subject).to_not receive(:rebuild_suite_tab_cache).with(kit.product)
          subject.perform
        end
      end

      context "with optional part coming into stock" do
        let(:kit) {create(:base_variant, in_stock_cache: true)}
        let(:part) {create(:base_variant, in_stock_cache: false)}
        before do
          allow(part).to receive(:can_supply?).and_return true
        end

        it "does not influence the in_stock_cache" do
          expect(kit.in_stock_cache).to be_truthy
          subject.perform
          expect(kit.reload.in_stock_cache).to be_truthy
        end

        it "does not trigger the suite_tab_cache_rebuilder" do
          expect(subject).to_not receive(:rebuild_suite_tab_cache).with(kit.product)
          subject.perform
        end
      end
    end

    context "kit in_stock" do

      let(:kit) {create(:base_variant, in_stock_cache: true)}
      subject { Spree::StockCheckJob.new(part) }
      context "with all required parts in stock" do

        it "Does not alter the in_stock_cache" do
          expect(kit.in_stock_cache).to be_truthy
          subject.perform
          expect(kit.reload.in_stock_cache).to be_truthy
        end

        it "does not trigger the suite_tab_cache_rebuilder" do
          expect(subject).to_not receive(:rebuild_suite_tab_cache).with(kit.product)
          subject.perform
        end

      end

      context "with one required part out of stock" do
        let(:another_part) {create(:base_variant, in_stock_cache: false)}

        before do
          allow(another_part).to receive(:can_supply?).and_return false
        end

        it "sets the kit to out of stock" do
          expect(kit.in_stock_cache).to be_truthy
          subject.perform
          expect(kit.reload.in_stock_cache).to be_falsey
        end

        it "does trigger the suite_tab_cache_rebuilder" do
          expect(subject).to receive(:rebuild_suite_tab_cache).with(kit.product)
          subject.perform
        end
      end

      context "with one required part coming into stock" do
        let(:part) {create(:base_variant, in_stock_cache: false)}

        before do
          allow(part).to receive(:can_supply?).and_return true
        end

        it "does not change the in_stock cache" do
          expect(kit.in_stock_cache).to be_truthy
          subject.perform
          expect(kit.reload.in_stock_cache).to be_truthy
        end

        it "does not trigger the suite_tab_cache_rebuilder" do
          expect(subject).to_not receive(:rebuild_suite_tab_cache).with(kit.product)
          subject.perform
        end
      end

      context "with one required part going out of stock" do
        let(:part) {create(:base_variant, in_stock_cache: true)}

        before do
          allow(part).to receive(:can_supply?).and_return false
        end

        it "sets the kit to out of stock" do
          expect(kit.in_stock_cache).to be_truthy
          subject.perform
          expect(kit.reload.in_stock_cache).to be_falsey
        end

        it "does trigger the suite_tab_cache_rebuilder" do
          expect(subject).to receive(:rebuild_suite_tab_cache).with(kit.product)
          subject.perform
        end
      end

    end

    context "kit out of stock" do
      let(:kit) {create(:base_variant, in_stock_cache: false)}
      subject { Spree::StockCheckJob.new(part) }

      context "with all required parts in stock" do

        it "sets the kit to in stock" do
          expect(kit.in_stock_cache).to be_falsey
          subject.perform
          expect(kit.reload.in_stock_cache).to be_truthy
        end

        it "does trigger the suite_tab_cache_rebuilder" do
          expect(subject).to receive(:rebuild_suite_tab_cache).with(kit.product)
          subject.perform
        end

      end

      context "with one required part out of stock" do
        let(:another_part) {create(:base_variant, in_stock_cache: false)}

        before do
          allow(another_part).to receive(:can_supply?).and_return false
        end

        it "sets the kit to out ofstock" do
          expect(kit.in_stock_cache).to be_falsey
          subject.perform
          expect(kit.reload.in_stock_cache).to be_falsey
        end

        it "does not trigger the suite_tab_cache_rebuilder" do
          expect(subject).to_not receive(:rebuild_suite_tab_cache).with(kit.product)
          subject.perform
        end
      end

      context "with one required part coming into stock" do
        let(:part) {create(:base_variant, in_stock_cache: false)}

        before do
          allow(part).to receive(:can_supply?).and_return true
        end

        it "sets the kit to out ofstock" do
          expect(kit.in_stock_cache).to be_falsey
          subject.perform
          expect(kit.reload.in_stock_cache).to be_truthy
        end

        it "does trigger the suite_tab_cache_rebuilder" do
          expect(subject).to receive(:rebuild_suite_tab_cache).with(kit.product)
          subject.perform
        end
      end

      context "with one required part going out of stock" do
        let(:part) {create(:base_variant, in_stock_cache: true)}

        before do
          allow(part).to receive(:can_supply?).and_return false
        end

        it "sets the kit to out ofstock" do
          expect(kit.in_stock_cache).to be_falsey
          subject.perform
          expect(kit.reload.in_stock_cache).to be_falsey
        end

        it "does trigger the suite_tab_cache_rebuilder" do
          expect(subject).to_not receive(:rebuild_suite_tab_cache).with(kit.product)
          subject.perform
        end
      end

    end

    context "check the kit and then traverse its parts" do
      subject { Spree::StockCheckJob.new(kit) }

      context "Kit is out of stock with all required parts" do

        let(:kit) {create(:base_variant, in_stock_cache: false)}
        subject { Spree::StockCheckJob.new(kit) }


        it "sets the kit to in stock" do
          expect(kit.in_stock_cache).to be_falsey
          subject.perform
          expect(kit.reload.in_stock_cache).to be_truthy
        end

        it "does trigger the suite_tab_cache_rebuilder" do
          expect(subject).to receive(:rebuild_suite_tab_cache).with(kit.product)
          subject.perform
        end

      end

      context "Kit is in stock with a required part out of stock" do

        let(:kit) {create(:base_variant, in_stock_cache: true)}
        let(:part) {create(:base_variant, in_stock_cache: false)}


        it "sets the kit to in stock" do
          expect(kit.in_stock_cache).to be_truthy
          subject.perform
          expect(kit.reload.in_stock_cache).to be_falsey
        end

        it "does trigger the suite_tab_cache_rebuilder" do
          expect(subject).to receive(:rebuild_suite_tab_cache).with(kit.product)
          subject.perform
        end

        before do
          allow_any_instance_of(Spree::StockItem).to receive_messages(backorderable: false)
        end

        context "Kit is out of stock with a optional part out of stock" do

          let(:kit) {create(:base_variant, in_stock_cache: false)}
          let(:part) {create(:base_variant, in_stock_cache: false)}
          let!(:ap) do
            Spree::StaticAssembliesPart.create(part_id: part.id, assembly_id: kit.id, assembly_type: 'Spree::Variant', count: 1, optional: true)
          end


          it "sets the kit to in stock" do
            expect(kit.in_stock_cache).to be_falsey
            subject.perform
            expect(kit.reload.in_stock_cache).to be_truthy
          end

          it "does trigger the suite_tab_cache_rebuilder" do
            expect(subject).to receive(:rebuild_suite_tab_cache).with(kit.product)
            subject.perform
          end

        end

        context "nothing changes" do

          let(:kit) {create(:base_variant, in_stock_cache: true)}
          let(:part) {create(:base_variant, in_stock_cache: true)}


          it "sets the kit to in stock" do
            expect(kit.in_stock_cache).to be_truthy
            subject.perform
            expect(kit.reload.in_stock_cache).to be_truthy
          end

          it "does not trigger the suite_tab_cache_rebuilder" do
            expect(subject).to_not receive(:rebuild_suite_tab_cache).with(kit.product)
            subject.perform
          end

        end

      end

    end

    describe "Dynamic Kit ( Assembly Defintion )" do
      include_context "assembly definition light"

      before do
        allow(subject).to receive(:rebuild_suite_tab_cache)
        allow(subject).to receive(:persist_updates)
      end

      describe "stock check for the the Assembly Definition variant e.g. Kit itself" do
        subject { Spree::StockCheckJob.new(variant) }

        context "Kit is in stock but can supply if false" do
          before do
            variant.in_stock_cache = true
            allow(variant).to receive(:can_supply?).and_return false
          end

          it "in stock cache does not change" do
            subject.perform
            expect(variant.in_stock_cache).to be_truthy
          end

          it "triggers the suite_tab_cache_rebuilder" do
            expect(subject).to_not receive(:rebuild_suite_tab_cache).with(variant.product)
            subject.perform
          end

        end

        context "Kit is out of stock and has missing required parts, but can supply is true" do
          before do
            variant.in_stock_cache = false
            variant_part.in_stock_cache = false
            allow(variant).to receive(:can_supply?).and_return true
          end

          it "in stock cache does not change" do
            subject.perform
            expect(variant.in_stock_cache).to be_falsey
          end

          it "triggers the suite_tab_cache_rebuilder" do
            expect(subject).to_not receive(:rebuild_suite_tab_cache).with(variant.product)
            subject.perform
          end

        end
      end

      describe "check stock for the assembly parts" do
        subject { Spree::StockCheckJob.new(variant_part) }

        before do
          allow(variant_part).to receive(:can_supply?).and_return true
        end

        context "Kit is out of stock but has all required parts in stock" do

          before do
            variant.in_stock_cache = false
            variant_part.in_stock_cache = true
            allow(variant_part).to receive(:can_supply?).and_return true
          end

          it "puts the kit back in stock" do
            expect(variant.in_stock_cache).to be_falsey
            subject.perform
            expect(variant.in_stock_cache).to be_truthy
          end

          it "triggers the suite_tab_cache_rebuilder" do
            expect(subject).to receive(:rebuild_suite_tab_cache).with(variant.product)
            subject.perform
          end

        end

        context "Kit is in stock and has all required parts in stock" do

          before do
            variant.in_stock_cache = true
            variant_part.in_stock_cache = true
            allow(variant_part).to receive(:can_supply?).and_return true
          end

          it "does not change stock status of kit" do
            expect(variant.in_stock_cache).to be_truthy
            subject.perform
            expect(variant.in_stock_cache).to be_truthy
          end

          it "does not trigger the suite_tab_cache_rebuilder" do
            expect(subject).to_not receive(:rebuild_suite_tab_cache).with(variant.product)
            subject.perform
          end

        end

        context "Kit is out ofstock and required part has just come into stock" do

          before do
            variant.in_stock_cache = false
            variant_part.in_stock_cache = false
            allow(variant_part).to receive(:can_supply?).and_return true
          end

          it "does not change stock status of kit" do
            expect(variant.in_stock_cache).to be_falsey
            subject.perform
            expect(variant.in_stock_cache).to be_truthy
          end

          it "does not trigger the suite_tab_cache_rebuilder" do
            expect(subject).to receive(:rebuild_suite_tab_cache).with(variant.product)
            subject.perform
          end

        end

        context "Kit is in stock and required part has just gone out of stock" do

          before do
            variant.in_stock_cache = true
            variant_part.in_stock_cache = true
            allow(variant_part).to receive(:can_supply?).and_return false
          end

          it "does not change stock status of kit" do
            expect(variant.in_stock_cache).to be_truthy
            subject.perform
            expect(variant.in_stock_cache).to be_falsey
          end

          it "does not trigger the suite_tab_cache_rebuilder" do
            expect(subject).to receive(:rebuild_suite_tab_cache).with(variant.product)
            subject.perform
          end

        end

        context "more than 1 variant" do

          let(:another_variant_part)  { Spree::Variant.new(number: "V1111", product: product_part, in_stock_cache: false, updated_at: 2.days.ago) }
          let(:another_adv) { Spree::AssemblyDefinitionVariant.new(assembly_definition_part: adp, variant: variant_part) }

          before(:each) do
            another_variant_part.assembly_definition_variants << another_adv
            adp.variants << another_variant_part
          end

          context "required part has 1 variant in stock another out of stock" do

            before do
              allow(variant_part).to receive(:can_supply?).and_return true
              variant.in_stock_cache = false
              variant_part.in_stock_cache = true
              another_variant_part.in_stock_cache = true
            end

            it "puts the kit back in stock" do
              expect(variant.in_stock_cache).to be_falsey
              subject.perform
              expect(variant.in_stock_cache).to be_truthy
            end

            it "triggers the suite_tab_cache_rebuilder" do
              expect(subject).to receive(:rebuild_suite_tab_cache).with(variant.product)
              subject.perform
            end

          end

          context "required part has 1 variant out of stock another going out of stock" do

            before do
              allow(variant_part).to receive(:can_supply?).and_return false
              variant.in_stock_cache = true
              variant_part.in_stock_cache = true
              another_variant_part.in_stock_cache = false
            end

            it "puts the kit back in stock" do
              expect(variant.in_stock_cache).to be_truthy
              subject.perform
              expect(variant.in_stock_cache).to be_falsey
            end

            it "triggers the suite_tab_cache_rebuilder" do
              expect(subject).to receive(:rebuild_suite_tab_cache).with(variant.product)
              subject.perform
            end

          end

          context "required part has 1 variant in stock another going out of stock" do

            before do
              allow(variant_part).to receive(:can_supply?).and_return false
              allow(another_variant_part).to receive(:can_supply?).and_return true
              variant.in_stock_cache = true
              variant_part.in_stock_cache = true
              another_variant_part.in_stock_cache = true
            end

            it "puts the kit back in stock" do
              expect(variant.in_stock_cache).to be_truthy
              subject.perform
              expect(variant.in_stock_cache).to be_truthy
            end

          end


        end

        context "more than 1 part" do

          let(:another_product_part)  { Spree::Product.new() }
          let(:another_variant_part)  { Spree::Variant.new(number: "V1111", product: another_product_part, in_stock_cache: false, updated_at: 2.days.ago) }
          let(:another_adp) { Spree::AssemblyDefinitionPart.new(assembly_definition: assembly_definition, product: another_product_part, optional: false) }
          let(:another_adv) { Spree::AssemblyDefinitionVariant.new(assembly_definition_part: adp, variant: variant_part) }

          before(:each) do
            another_variant_part.assembly_definition_variants << another_adv
            another_adp.variants << another_variant_part
            assembly_definition.parts << another_adp
          end

          context "and one of them is in stock (required) the other is out of stock ( required )" do

            before do
              allow(another_variant_part).to receive(:can_supply?).and_return false
            end

            context "kit is originaly out of stock" do

              before do
                variant.in_stock_cache = false
              end

              it "does not put the assembly back in stock" do
                subject.perform
                expect(variant.in_stock_cache).to be_falsey
              end

              it "does not trigger the suite_tab_cache_rebuilder" do
                expect(subject).to_not receive(:rebuild_suite_tab_cache).with(variant.product)
                subject.perform
              end

            end

            context "kit is originaly in stock" do

              before do
                variant.in_stock_cache = true
              end

              it "does put the assembly back in stock" do
                subject.perform
                expect(variant.in_stock_cache).to be_falsey
              end

              it "does trigger the suite_tab_cache_rebuilder" do
                expect(subject).to receive(:rebuild_suite_tab_cache).with(variant.product)
                subject.perform
              end

            end

          end

          context "and one of them is in stock (required) the other is out of stock ( optional )" do

            before do
              allow(another_variant_part).to receive(:can_supply?).and_return false
              another_adp.optional = true
            end

            context "kit is originaly out of stock" do

              before do
                variant.in_stock_cache = false
              end

              it "puts the assembly back in stock" do
                subject.perform
                expect(variant.in_stock_cache).to be_truthy
              end

              it "does trigger the suite_tab_cache_rebuilder" do
                expect(subject).to receive(:rebuild_suite_tab_cache).with(variant.product)
                subject.perform
              end

            end

            context "kit is originaly in stock" do

              before do
                variant.in_stock_cache = true
              end

              it "does not change the in_stock value" do
                subject.perform
                expect(variant.in_stock_cache).to be_truthy
              end

              it "does not trigger the suite_tab_cache_rebuilder" do
                expect(subject).to_not receive(:rebuild_suite_tab_cache).with(variant.product)
                subject.perform
              end

            end

          end

        end

      end

      context "check the kit and then traverse its parts" do
        subject { Spree::StockCheckJob.new(variant) }

        context "Kit is out of stock with all required parts" do

          before do
            variant.in_stock_cache = false
            variant_part.in_stock_cache = true
          end

          it "sets the kit to in stock" do
            expect(variant.in_stock_cache).to be_falsey
            subject.perform
            expect(variant.in_stock_cache).to be_truthy
          end

          it "does trigger the suite_tab_cache_rebuilder" do
            expect(subject).to receive(:rebuild_suite_tab_cache).with(variant.product)
            subject.perform
          end

        end

        context "Kit is in stock with a required part out of stock" do

          before do
            variant.in_stock_cache = true
            variant_part.in_stock_cache = false
          end

          it "sets the kit to in stock" do
            expect(variant.in_stock_cache).to be_truthy
            subject.perform
            expect(variant.in_stock_cache).to be_falsey
          end

          it "does trigger the suite_tab_cache_rebuilder" do
            expect(subject).to receive(:rebuild_suite_tab_cache).with(variant.product)
            subject.perform
          end

        end

        context "Kit is out of stock with a optional part out of stock" do

          let(:kit) {create(:base_variant, in_stock_cache: false)}
          let(:part) {create(:base_variant, in_stock_cache: false)}
          let!(:ap) do
            Spree::StaticAssembliesPart.create(part_id: part.id, assembly_id: kit.id, assembly_type: 'Spree::Variant', count: 1, optional: true)
          end

          before do
            variant.in_stock_cache = false
            variant_part.in_stock_cache = false
            adp.optional = true
          end

          it "sets the kit to in stock" do
            expect(variant.in_stock_cache).to be_falsey
            subject.perform
            expect(variant.in_stock_cache).to be_truthy
          end

          it "does trigger the suite_tab_cache_rebuilder" do
            expect(subject).to receive(:rebuild_suite_tab_cache).with(variant.product)
            subject.perform
          end

        end

        context "nothing changes" do

          before do
            variant.in_stock_cache = true
            variant_part.in_stock_cache = true
          end

          it "sets the kit to in stock" do
            expect(variant.in_stock_cache).to be_truthy
            subject.perform
            expect(variant.in_stock_cache).to be_truthy
          end

          it "does not trigger the suite_tab_cache_rebuilder" do
            expect(subject).to_not receive(:rebuild_suite_tab_cache).with(variant.product)
            subject.perform
          end

        end

      end

    end

    context "Dynamic kit where part is a static kit" do
      let!(:product) { create(:base_product, name: "My Product", description: "Product Description") }
      let!(:variant) { create(:base_variant, product: product, in_stock_cache: true, number: "V1234", updated_at: 1.day.ago) }

      let!(:product_part)  { create(:base_product) }
      let!(:static_kit) {create(:base_variant, in_stock_cache: true, product: product_part)}
      let!(:static_kit_part) {create(:base_variant, in_stock_cache: true)}
      let!(:ap) do
        Spree::StaticAssembliesPart.create(part_id: static_kit_part.id, assembly_id: static_kit.id, assembly_type: 'Spree::Variant', count: 1, optional: false)
      end

      let!(:assembly_definition) { create(:assembly_definition, variant: variant) }
      let!(:adp) { Spree::AssemblyDefinitionPart.create(assembly_definition: assembly_definition, product: product_part, optional: false) }
      let!(:adv) { Spree::AssemblyDefinitionVariant.create(assembly_definition_part: adp, variant: static_kit) }

      subject { Spree::StockCheckJob.new(static_kit_part) }

      before do
        allow(subject).to receive(:rebuild_suite_tab_cache)
      end

      context "static kit part is going out of stock" do

        before do
          allow(static_kit_part).to receive(:can_supply?).and_return false
        end

        it "set the in_stock value to false" do
          expect(variant.in_stock_cache).to be_truthy
          subject.perform
          expect(variant.reload.in_stock_cache).to be_falsey
        end

        it "does rigger the suite_tab_cache_rebuilder" do
          expect(subject).to receive(:rebuild_suite_tab_cache).with(variant.product)
          subject.perform
        end

      end

      context "is coming into stock" do
        let!(:variant) { create(:base_variant, product: product, in_stock_cache: false, number: "V1234", updated_at: 1.day.ago) }
        let!(:static_kit_part) {create(:base_variant, in_stock_cache: false)}

        before do
          allow(static_kit_part).to receive(:can_supply?).and_return true
        end

        it "set the in_stock value to true" do
          expect(variant.in_stock_cache).to be_falsey
          subject.perform
          expect(variant.reload.in_stock_cache).to be_truthy
        end

        it "does rigger the suite_tab_cache_rebuilder" do
          expect(subject).to receive(:rebuild_suite_tab_cache).with(variant.product)
          subject.perform
        end

      end

      context "multiple variants of which one is going out of stock" do

        let!(:another_static_kit) {create(:base_variant, in_stock_cache: false, product: product_part)}
        let!(:another_adv) { Spree::AssemblyDefinitionVariant.create(assembly_definition_part: adp, variant: another_static_kit) }

        before do
          allow(static_kit_part).to receive(:can_supply?).and_return false
        end

        it "set the in_stock value to false" do
          expect(variant.in_stock_cache).to be_truthy
          subject.perform
          expect(variant.reload.in_stock_cache).to be_falsey
        end

      end
    end

    describe "fetch_dynamic_assemblies" do
      include_context "assembly definition"

      subject { described_class.new(variant_part) }

      it "returns no assemblies" do
        expect(subject.send(:fetch_dynamic_assemblies, adp)).to eq [assembly_definition]
      end

      context "when assemblies_definition is deleted" do
        before do
          assembly_definition.delete
        end

        it "returns no assemblies" do
          expect(subject.send(:fetch_dynamic_assemblies, adp)).to be_empty
        end
      end
    end
  end
end
