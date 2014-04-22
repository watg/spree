require 'spec_helper'

describe Spree::StockCheckJob do
  let(:variant_not_part) {create(:variant_with_stock_items)}
  let(:stock_item) { variant_not_part.stock_items.first }
  subject  { Spree::StockCheckJob.new(stock_item) }

  
  describe "#perform" do
    context "on variant part of NO kit" do
      before do
        allow_any_instance_of(Spree::Stock::Quantifier).
          to receive(:can_supply?).
          and_return(true)
      end

      it "updates just the variant" do
        expect(stock_item.variant).to receive(:update_attributes).with(in_stock_cache: true)
        subject.perform
      end
    end

    context "on variant which is a kit" do

      before do
        stock_item.variant.stub_chain(:isa_kit?).and_return true
      end

      it "does not update the variant" do
        expect_any_instance_of(Spree::StockCheckJob).not_to receive(:check_stock)
        subject.perform
      end
    end

    context "on variant part of a kit" do
      let(:part) { create(:variant_with_stock_items)}
      subject  { Spree::StockCheckJob.new(part.stock_items.first) }
      before do 
        Spree::AssembliesPart.create(part_id: part.id, assembly_id: variant_not_part.id, assembly_type: 'Spree::Variant', count: 4)
      end

      context "going in stock" do
        before do
          allow_any_instance_of(Spree::Stock::Quantifier).
            to receive(:can_supply?).
            and_return(true)
        end

        it "all of its parts are in stock" do
          expect(subject).to receive(:check_stock_for_kits_using_this_variant)
          subject.perform
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

  it "ignores any kit that have that part as optional" do
    arel = double('arel', group_by: {})
    
    expect(Spree::AssembliesPart).
      to receive(:where).
      with(part_id: variant_not_part.id, optional: false).
      and_return(arel)
    
    subject.send(:list_of_kit_variants_using, variant_not_part)
  end

  

end
