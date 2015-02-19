require "spec_helper"
describe Spree::OrderType, type: :model do
  let!(:order_type) { create(:order_type) }

  describe "regular" do
    it "returns the regular order_type" do
      expect(described_class.regular).to eq order_type
    end
  end

  describe "regular?" do
    it "returns true" do
      expect(order_type.regular?).to be true
    end
  end

  context "for an party order" do
    describe "party" do
      let!(:order_type) { create(:party_order_type) }

      it "returns the party order_type" do
        expect(described_class.party).to eq order_type
      end

      describe "party?" do
        it "returns true" do
          expect(order_type.party?).to be true
        end
      end
    end
  end
end
