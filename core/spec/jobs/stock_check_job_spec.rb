require 'spec_helper'

describe Spree::StockCheckJob do
  describe "ready to wear product with parts" do
    subject              { Spree::StockCheckJob.new(variant) }
    let(:variant)        { create(:master_variant, in_stock_cache: true) }
    let(:product)        { variant.product }
    let(:part)           { create(:product) }
    let(:part2)          { create(:product) }
    let(:part_variant)   { create(:master_variant, product: part, in_stock_cache: true) }
    let(:part2_variant)  { create(:master_variant, product: part2, in_stock_cache: true) }
    let(:ppv)            { create(:product_part_variant, ppv_opts) }
    let(:ppv_opts)       { { variant: part_variant, product_part: product.product_parts.first } }
    let(:ppv2)           { create(:product_part_variant, ppv2_opts) }
    let(:ppv2_opts)      { { variant: part2_variant, product_part: product.product_parts.last } }

    before do
      product.master = variant
      variant.product.parts = [part, part2]
      product.product_parts.first.product_part_variants = [ppv]
      product.product_parts.last.product_part_variants = [ppv2]
    end

    context "variant is out of stock" do
      before { expect(variant).to receive(:can_supply?).and_return(false) }

      it "updates the variants stock cache" do
        subject.perform
        expect(variant.in_stock_cache).to be false
      end

      it "blows the suite tab cache" do
        expect(Spree::SuiteTabCacheRebuilder).to receive(:rebuild_from_product).with(product)
        subject.perform
      end
    end

    context "required part is out of stock" do
      subject              { Spree::StockCheckJob.new(part_variant) }
      let(:part_variant)   { create(:master_variant, product: part, in_stock_cache: false) }

      before               { expect(part_variant).to receive(:can_supply?).and_return(false) }

      it "updates the variants stock cache" do
        subject.perform
        expect(variant.reload.in_stock_cache).to be false
      end

      it "blows the suite tab cache" do
        expect(Spree::SuiteTabCacheRebuilder).to receive(:rebuild_from_product).with(product)
        subject.perform
      end
    end
  end

  describe "variant, which is not part of any kit" do
    let(:variant_not_part) {create(:variant, in_stock_cache: true, updated_at: 1.day.ago)}
    subject { Spree::StockCheckJob.new(variant_not_part) }

    before do
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
      subject   { Spree::StockCheckJob.new(part) }
      let(:kit) { create(:base_variant, in_stock_cache: true) }

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
        let(:another_part) { create(:base_variant, in_stock_cache: false) }

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
        let(:part) { create(:base_variant, in_stock_cache: true) }

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
      subject   { Spree::StockCheckJob.new(part) }
      let(:kit) { create(:base_variant, in_stock_cache: false) }

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
  end
end
