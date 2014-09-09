require 'spec_helper'

describe Spree::StockCheckJob do
  let(:variant_not_part) {create(:variant_with_stock_items)}
  let(:stock_item) { variant_not_part.stock_items.first }
  subject  { Spree::StockCheckJob.new(variant_not_part) }

  
  describe "#perform" do
    context "on variant part of NO kit" do
      before do
        allow_any_instance_of(Spree::Stock::Quantifier).
          to receive(:can_supply?).
          and_return(true)
        stock_item.variant.in_stock_cache = false
      end

      it "updates just the variant" do
        expect(stock_item.variant).to receive(:update_attributes).with(in_stock_cache: true)
        subject.perform
      end
    end

    context "on variant part of a kit" do
      let(:kit) {create(:base_variant)}
      let(:part) { create(:variant_with_stock_items)}
      let(:another_part) { create(:variant_with_stock_items)}
      let(:out_of_stock_part) { create(:variant)}
      let!(:ap) do
        Spree::AssembliesPart.create(part_id: part.id, assembly_id: kit.id, assembly_type: 'Spree::Variant', count: 1)
      end

      subject  { Spree::StockCheckJob.new(part) }

      before do 
        Spree::StockItem.any_instance.stub(backorderable: false)
      end

      context "kit with 1 part in stock" do

        before do 
          kit.in_stock_cache = false
        end

        it "is in stock" do
          subject.perform
          expect(kit.reload.in_stock_cache).to eq(true)
        end

      end

      context "kit with 1 part out of stock" do

        before do 
          kit.in_stock_cache = true
          ap.update_column(:part_id, out_of_stock_part.id)
        end


        it "is out of stock when part is out of stock" do
          subject.perform
          expect(kit.reload.in_stock_cache).to eq(false)
        end

      end

      context "kit with 1 part in stock and another part out of stock" do

        before do 
          kit.in_stock_cache = true
          Spree::AssembliesPart.create(part_id: out_of_stock_part.id, assembly_id: kit.id, assembly_type: 'Spree::Variant', count: 1)
        end

        it "is not in stock" do
          subject.perform
          expect(kit.reload.in_stock_cache).to eq(false)
        end

      end

      context "kit with 1 part in stock and another part out of stock which is optional" do

        before do 
          kit.in_stock_cache = false
          Spree::AssembliesPart.create(part_id: out_of_stock_part.id, assembly_id: kit.id, assembly_type: 'Spree::Variant', count: 1, optional: true)
        end

        it "is not in stock" do
          subject.perform
          expect(kit.reload.in_stock_cache).to eq(true)
        end

      end

      context "kit with part out of stock and another part in stock" do

        before do 
          kit.in_stock_cache = true
          ap.update_column(:part_id, out_of_stock_part.id)
          Spree::AssembliesPart.create(part_id: part.id, assembly_id: kit.id, assembly_type: 'Spree::Variant', count: 1)
        end

        it "is not in stock" do
          subject.perform
          expect(kit.reload.in_stock_cache).to eq(false)
        end

      end

      context "kit with part in stock and another part in stock" do

        before do 
          kit.in_stock_cache = false
          Spree::AssembliesPart.create(part_id: another_part.id, assembly_id: kit.id, assembly_type: 'Spree::Variant', count: 1)
        end

        it "is not in stock" do
          subject.perform
          expect(kit.reload.in_stock_cache).to eq(true)
        end

      end

      context "going out of stock" do
        before do
          allow_any_instance_of(Spree::Stock::Quantifier).
            to receive(:can_supply?).
            and_return(false)
        end

        it "updates part own stock to out of stock" do
          subject.perform
          expect(part.reload.in_stock_cache).to eq(false)
        end

        it "put out of stock all kit that have that part" do
          expect(subject).to receive(:put_all_kits_using_this_variant_out_of_stock)
          subject.perform
        end
      end

    end

  end

end
