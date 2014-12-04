require 'spec_helper'

describe Spree::Taxonomy do
  context "#destroy" do
    let(:taxonomy) { create(:taxonomy) }

    before do
       @root_taxon = taxonomy.root
       @child_taxon = create(:taxon, :taxonomy_id => taxonomy.id, :parent => @root_taxon)
    end

    it "should destroy all associated taxons" do
      taxonomy.destroy
      expect{ Spree::Taxon.find(@root_taxon.id) }.to raise_error(ActiveRecord::RecordNotFound)
      expect{ Spree::Taxon.find(@child_taxon.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    describe "#after_save" do

      context "clear_navigation_cache_key" do
        it "gets called" do
          expect(taxonomy).to receive(:clear_navigation_cache_key)
          taxonomy.save!
        end
      end

    end

    describe "#after_touch" do

      context "clear_navigation_cache_key" do
        it "gets called" do
          expect(taxonomy).to receive(:clear_navigation_cache_key)
          taxonomy.touch
        end
      end

    end

    describe "navigation_cache_key" do

      before do
        Rails.cache.delete(Spree::Taxonomy::NAVIGATION_CACHE_KEY)
      end

      it "sets if it does not exist" do
        expect(Rails.cache.read(Spree::Taxonomy::NAVIGATION_CACHE_KEY)).to be_nil
        expect(Spree::Taxonomy.navigation_cache_key).to_not be_nil
      end


      describe "#clear_navigation_cache_key" do

        before do
          Rails.cache.write(Spree::Taxonomy::NAVIGATION_CACHE_KEY, 'lol')
        end

        it "clears the key" do
          expect(Rails.cache.read(Spree::Taxonomy::NAVIGATION_CACHE_KEY)).not_to be_nil
          taxonomy.clear_navigation_cache_key
          expect(Rails.cache.read(Spree::Taxonomy::NAVIGATION_CACHE_KEY)).to be_nil
        end

      end

    end

  end
end

