require 'spec_helper'

module Spree

  describe Spree::VariantDuplicator do

    let(:variant) { create(:variant_in_sale) }
    let!(:duplicator) { Spree::VariantDuplicator.new(variant)}

    context "duplicate_prices" do

      it "will duplicate the prices" do
        expect(duplicator.duplicate_prices.count).to eq (variant.prices.count)
      end

      it "removes reference to the existing variant" do
        expect(duplicator.duplicate_prices.first.variant_id).to be_nil
      end

    end
  end
end
