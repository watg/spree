require "spec_helper"

describe Spree::StockCheckJob do
  describe "Dynamic Kit ( Assembly Defintion )" do
    let(:klass)          { Spree::StockCheckJob }
    let!(:variant)       { create(:master_variant, variant_opts) }
    let(:variant_opts)   { { product: product, in_stock_cache: variant_status } }
    let!(:product)       { create(:product, product_type: product_type) }
    let(:product_type)   { create(:product_type, :kit) }
    let(:variant_status) { in_stock }
    let(:in_stock)       { true }
    let(:out_of_stock)   { false }
    let!(:part_product)  { create(:product) }
    let!(:pv)            { create(:variant, product: part_product, in_stock_cache: pv_status) }
    let(:pv_status)      { in_stock }
    let!(:adp)           { create(:product_part, adp_opts) }
    let(:adp_opts)       { { product: variant.product, part: part_product, optional: false } }
    let!(:adv)           { create(:product_part_variant, adv_opts) }
    let(:adv_opts)       { { product_part: adp, variant: pv } }

    before               { product.master = variant }

    describe "stock check for the the Assembly Definition variant e.g. Kit itself" do
      subject  { klass.new(variant) }

      context "Kit is in stock but can supply if false" do
        let(:variant_status) { in_stock }

        before { allow(variant).to receive(:can_supply?).and_return false }

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
        let(:variant_status) { out_of_stock }
        let(:pv_status)      { out_of_stock }

        before { allow(variant).to receive(:can_supply?).and_return true }

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
      subject { klass.new(pv) }

      before  { allow(pv).to receive(:can_supply?).and_return true }

      context "Kit is out of stock but has all required parts in stock" do
        let(:variant_status) { out_of_stock }
        let(:pv_status)      { in_stock }

        before { allow(pv).to receive(:can_supply?).and_return true }

        it "puts the kit back in stock" do
          expect(variant.in_stock_cache).to be_falsey
          subject.perform
          expect(variant.reload.in_stock_cache).to be_truthy
        end

        it "triggers the suite_tab_cache_rebuilder" do
          expect(subject).to receive(:rebuild_suite_tab_cache).with(variant.product)
          subject.perform
        end
      end

      context "Kit is in stock and has all required parts in stock" do
        let(:variant_status) { in_stock }
        let(:pv_status)      { in_stock }

        before { allow(pv).to receive(:can_supply?).and_return true }

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

      context "Kit is out of stock and required part has just come into stock" do
        let(:variant_status) { out_of_stock }
        let(:pv_status)      { out_of_stock }

        before { allow(pv).to receive(:can_supply?).and_return true }

        it "does not change stock status of kit" do
          expect(variant.in_stock_cache).to be_falsey
          subject.perform
          expect(variant.reload.in_stock_cache).to be_truthy
        end

        it "does not trigger the suite_tab_cache_rebuilder" do
          expect(subject).to receive(:rebuild_suite_tab_cache).with(pv.product)
          expect(subject).to receive(:rebuild_suite_tab_cache).with(variant.product)
          subject.perform
        end
      end

      context "Kit is in stock and required part has just gone out of stock" do
        let(:variant_status) { in_stock }
        let(:pv_status)      { in_stock }

        before { allow(pv).to receive(:can_supply?).and_return false }

        it "does not change stock status of kit" do
          expect(variant.in_stock_cache).to be_truthy
          subject.perform
          expect(variant.reload.in_stock_cache).to be_falsey
        end

        it "does not trigger the suite_tab_cache_rebuilder" do
          expect(subject).to receive(:rebuild_suite_tab_cache).with(pv.product)
          expect(subject).to receive(:rebuild_suite_tab_cache).with(variant.product)
          subject.perform
        end
      end

      context "more than 1 variant" do
        let(:pv_status)  { in_stock }
        let(:pv2)        { create(:variant, product: part_product, in_stock_cache: pv2_status) }
        let(:pv2_status) { out_of_stock }
        let(:adv_2)      { create(:product_part_variant, adv2_opts) }
        let(:adv_2_opts) { { product_part: adp, variant: pv2 } }

        context "required part has 1 variant in stock another out of stock" do
          let(:variant_status) { out_of_stock }

          it "puts the kit back in stock" do
            expect(variant.in_stock_cache).to be_falsey
            subject.perform
            expect(variant.reload.in_stock_cache).to be_truthy
          end

          it "triggers the suite_tab_cache_rebuilder" do
            expect(subject).to receive(:rebuild_suite_tab_cache).with(variant.product)
            subject.perform
          end
        end

        context "required part has 1 variant out of stock another going out of stock" do
          let(:variant_status) { in_stock }
          let(:pv_status)      { in_stock }
          let(:pv2_status)     { out_of_stock }

          before { allow(pv).to receive(:can_supply?).and_return false }

          it "puts the kit out of stock" do
            expect(variant.in_stock_cache).to be_truthy
            subject.perform
            expect(variant.reload.in_stock_cache).to be_falsey
          end

          it "triggers the suite_tab_cache_rebuilder" do
            expect(subject).to receive(:rebuild_suite_tab_cache).with(pv.product)
            expect(subject).to receive(:rebuild_suite_tab_cache).with(variant.product)
            subject.perform
          end
        end

        context "required part has 1 variant in stock another going out of stock" do
          let(:variant_status) { in_stock }
          let(:pv_status)      { in_stock }
          let(:pv2_status)     { in_stock }

          before do
            allow(pv).to receive(:can_supply?).and_return false
            allow(pv2).to receive(:can_supply?).and_return true
          end

          it "puts the kit back in stock" do
            expect(variant.in_stock_cache).to be_truthy
            subject.perform
            expect(variant.in_stock_cache).to be_truthy
          end
        end
      end

      context "more than 1 part" do
        let(:variant_status) { in_stock }
        let(:pv_status)      { in_stock }
        let(:part_2)         { create(:product) }
        let(:pv2)            { create(:variant, product: part_2, in_stock_cache: pv2_status) }
        let(:pv2_status)     { out_of_stock }
        let(:adp_2)          { create(:product_part, adp_2_opts) }
        let(:adp_2_opts)     { { product: product, part: part_2, optional: false } }
        let!(:adv2)          { create(:product_part_variant, adv2_opts) }
        let(:adv2_opts)      { { product_part: adp_2, variant: pv2 } }

        context "and one of them is in stock (required) the other is out of stock ( required )" do
          before { allow(pv2).to receive(:can_supply?).and_return false }

          context "kit is originaly out of stock" do
            let(:variant_status) { out_of_stock }

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
            let(:variant_status) { in_stock }

            it "does put the assembly back in stock" do
              subject.perform
              expect(variant.reload.in_stock_cache).to be_falsey
            end

            it "does trigger the suite_tab_cache_rebuilder" do
              expect(subject).to receive(:rebuild_suite_tab_cache).with(variant.product)
              subject.perform
            end
          end
        end

        context "and one of them is in stock (required) the other is out of stock ( optional )" do
          let(:adp_2)      { create(:product_part, adp_2_opts) }
          let(:adp_2_opts) { { product: product, part: part_2, optional: true } }

          before           { allow(pv2).to receive(:can_supply?).and_return false }

          context "kit is originaly out of stock" do
            let(:variant_status) { out_of_stock }

            it "puts the assembly back in stock" do
              subject.perform
              expect(variant.reload.in_stock_cache).to be_truthy
            end

            it "does trigger the suite_tab_cache_rebuilder" do
              expect(subject).to receive(:rebuild_suite_tab_cache).with(variant.product)
              subject.perform
            end
          end

          context "kit is originaly in stock" do
            before { variant.in_stock_cache = true }

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
      subject { klass.new(variant) }

      context "Kit is out of stock with all required parts" do
        let(:variant_status) { out_of_stock }
        let(:pv_status)      { in_stock }

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
        let(:variant_status) { in_stock }
        let(:pv_status)      { out_of_stock }

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
        let(:variant_status) { out_of_stock }
        let(:pv_status)      { out_of_stock }
        let(:adp_opts) do
          { product: variant.product, part: part_product, optional: true }
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
        let(:variant_status) { in_stock }
        let(:pv_status)      { in_stock }

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
    let!(:product)     { create(:base_product, name: "My Product", product_type: product_type) }
    let(:product_type) { create(:product_type, :kit) }
    let!(:variant)     { create(:master_variant, variant_opts) }
    let(:variant_opts) { { product: product, in_stock_cache: true, updated_at: 1.day.ago } }

    let!(:product_part)  { create(:base_product) }
    let!(:sk) { create(:master_variant, static_kit_opts) }
    let(:static_kit_opts) { { in_stock_cache: true, product: product_part, number: "99999" } }
    let!(:skp) { create(:master_variant, in_stock_cache: true, number: "bite_me") }
    let!(:ap) { Spree::StaticAssembliesPart.create(ap_opts) }
    let(:ap_opts) { { part_id: skp.id, assembly_id: sk.id, assembly_type: "Spree::Variant" } }

    let!(:adp) { create(:product_part, adp_opts) }
    let!(:adp_opts) { { product: variant.product, part: product_part, optional: false } }
    let!(:adv) { adv_klass.create(product_part: adp, variant: sk) }
    let(:adv_klass) { Spree::ProductPartVariant }

    subject { Spree::StockCheckJob.new(skp) }

    before { product.master = variant }

    context "static kit part is going out of stock" do
      before do
        allow(skp).to receive(:can_supply?).and_return false
      end

      it "set the in_stock value to false" do
        expect(variant.in_stock_cache).to be_truthy
        subject.perform
        expect(variant.reload.in_stock_cache).to be_falsey
      end

      it "does trigger the suite_tab_cache_rebuilder" do
        expect(subject).to receive(:rebuild_suite_tab_cache).with(skp.product)
        expect(subject).to receive(:rebuild_suite_tab_cache).with(sk.product)
        expect(subject).to receive(:rebuild_suite_tab_cache).with(variant.product)
        subject.perform
      end
    end

    context "is coming into stock" do
      let(:variant)         { create(:master_variant, variant_opts) }
      let(:variant_opts)    { { product: product, in_stock_cache: false, updated_at: 1.day.ago } }
      let(:skp) { create(:base_variant, in_stock_cache: false) }

      before { allow(skp).to receive(:can_supply?).and_return true }

      it "set the in_stock value to true" do
        expect(variant.in_stock_cache).to be_falsey
        subject.perform
        expect(variant.reload.in_stock_cache).to be_truthy
      end

      it "triggers the suite_tab_cache_rebuilder" do
        expect(subject).to receive(:rebuild_suite_tab_cache).with(skp.product)
        expect(subject).to receive(:rebuild_suite_tab_cache).with(variant.product)
        subject.perform
      end
    end

    context "multiple variants of which one is going out of stock" do
      let!(:static_kit_2) { create(:base_variant, in_stock_cache: false, product: product_part) }
      let!(:adv_3)        { adv_klass.create(product_part: adp, variant: static_kit_2) }
      let(:adv_klass)     { Spree::ProductPartVariant }

      before { allow(skp).to receive(:can_supply?).and_return false }

      it "set the in_stock value to false" do
        expect(variant.in_stock_cache).to be_truthy
        subject.perform
        expect(variant.reload.in_stock_cache).to be_falsey
      end
    end
  end
end
