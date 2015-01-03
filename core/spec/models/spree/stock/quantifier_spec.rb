require 'spec_helper'

shared_examples_for 'unlimited supply' do
  it 'can_supply? any amount' do
    expect(subject.can_supply?(1)).to be true
    expect(subject.can_supply?(101)).to be true
    expect(subject.can_supply?(100_001)).to be true
  end
end

module Spree
  module Stock
    describe Quantifier do

#      before(:all) { Spree::StockLocation.destroy_all } #FIXME leaky database

      let!(:stock_location) { create :stock_location_with_items  }
      let!(:stock_item) { stock_location.stock_items.order(:id).first }

      subject { described_class.new(stock_item.variant) }

      specify { expect(subject.stock_items).to eq([stock_item]) }

      describe "clear_total_on_hand_cache" do
        it "clears the total_on_hand cache key" do
          expect(Rails.cache).to receive(:delete).with(subject.send(:total_on_hand_cache_key))
          subject.clear_total_on_hand_cache
        end
      end

      describe "total_on_hand_cache_key" do
        it "is unique to the variant" do
          expect(subject.send(:total_on_hand_cache_key)).to eq "variant-#{stock_item.variant.id}-total_on_hand"
        end
      end

      describe "clear_backorderable_cache" do
        it "clears the backorderable cache key" do
          expect(Rails.cache).to receive(:delete).with(subject.send(:backorderable_cache_key))
          subject.clear_backorderable_cache
        end
      end


      describe "backorderable_cache_key" do
        it "is unique to the variant" do
          expect(subject.send(:backorderable_cache_key)).to eq "variant-#{stock_item.variant.id}-backorderable"
        end
      end

      context 'with a single stock location/item' do
        describe "total_on_hand" do
          let(:variant) { stock_item.variant }

          it 'matches stock_item' do
            expect(subject.total_on_hand).to eq(stock_item.count_on_hand)
          end

          it 'deducts awaiting_feed inventory units' do
            create_list(:inventory_unit, 2, state: "awaiting_feed", variant: variant, pending: false)
            create_list(:inventory_unit, 2, state: "awaiting_feed", variant: variant, pending: true)
            expect(subject.total_on_hand).to eq(stock_item.count_on_hand - 2)
          end

          it 'uses rails cache' do
            expect(Rails.cache).to receive(:fetch).with(subject.send(:total_on_hand_cache_key))
            subject.total_on_hand
          end

          it 'caches the value' do
            expect(Spree::InventoryUnit).to receive(:total_awaiting_feed_for).and_return(0)
            subject.total_on_hand

            expect(Spree::InventoryUnit).to_not receive(:total_awaiting_feed_for)
            subject.total_on_hand
          end

        end

        describe "backorderable?" do
          it 'uses rails cache' do
            expect(Rails.cache).to receive(:fetch).with(subject.send(:backorderable_cache_key))
            subject.backorderable? 
          end

          it 'caches the value' do
            expect(subject).to receive(:stock_items).and_return([])
            subject.backorderable?

            expect(subject).to_not receive(:stock_items)
            subject.backorderable?
          end

        end

        context 'when track_inventory_levels is false' do
          before { configure_spree_preferences { |config| config.track_inventory_levels = false } }

          specify { expect(subject.total_on_hand).to eq(Float::INFINITY) }

          it_should_behave_like 'unlimited supply'
        end

        context 'when variant inventory tracking is off' do
          before { stock_item.variant.track_inventory = false }

          specify { expect(subject.total_on_hand).to eq(Float::INFINITY) }

          it_should_behave_like 'unlimited supply'
        end

        context 'when stock item allows backordering' do

          specify { expect(subject.backorderable?).to be true }

          it_should_behave_like 'unlimited supply'
        end

        context 'when stock item prevents backordering' do
          before { stock_item.update_attributes(backorderable: false) }

          specify { expect(subject.backorderable?).to be false }

          it 'can_supply? only upto total_on_hand' do
            expect(subject.can_supply?(1)).to be true
            expect(subject.can_supply?(10)).to be true
            expect(subject.can_supply?(11)).to be false
          end
        end

      end

      context 'with multiple stock locations/items' do
        let!(:stock_location_2) { create :stock_location }
        let!(:stock_location_3) { create :stock_location, active: false }
        let!(:stock_location_4) { create :stock_location, feed_into: stock_location_2, active: false }

        before do
          stock_location_2.stock_items.where(variant_id: stock_item.variant).update_all(count_on_hand: 5, backorderable: false)
          stock_location_3.stock_items.where(variant_id: stock_item.variant).update_all(count_on_hand: 5, backorderable: false)
          stock_location_4.stock_items.where(variant_id: stock_item.variant).update_all(count_on_hand: 5, backorderable: false)
        end

        it 'total_on_hand should total all active stock_items' do
          expect(subject.total_on_hand).to eq(20)
        end


        context 'when any stock item allows backordering' do
          specify { expect(subject.backorderable?).to be true }

          it_should_behave_like 'unlimited supply'
        end

        context 'when all stock items prevent backordering' do
          before { stock_item.update_attributes(backorderable: false) }

          specify { expect(subject.backorderable?).to be false }

          it 'can_supply? upto total_on_hand' do
            expect(subject.can_supply?(1)).to be true
            expect(subject.can_supply?(15)).to be true
            expect(subject.can_supply?(20)).to be true
            expect(subject.can_supply?(21)).to be false
          end
        end

      end

    end
  end
end
