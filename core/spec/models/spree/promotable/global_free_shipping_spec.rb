require "spec_helper"

module Spree
  # a spec
  module Promotable
    describe GlobalFreeShipping, type: :model do
      subject { described_class.new("US", "USD") }

      let(:promotion) do
        create(:promotion, id:
               described_class::GLOBAL_FREE_SHIPPING_PROMOTION_ID
              )
      end
      let(:rule) do
        Spree::Promotion::Rules::ItemTotal.create!(
          promotion: promotion,  preferred_attributes: preferred_attributes)
      end
      let(:zone) do
        Spree::Zone.where(name: "GlobalZone").first || create(:global_zone)
      end

      context "when free shipping rules are found" do
        let(:preferred_attributes) do
          {
            zone.id.to_s  => { "USD" => {
              "amount" => "100", "enabled" => "true" }
            },
            "2" => { "EUR" => {
              "amount" => "120", "enabled" => "true" }
            }
          }
        end

        before do
          united_states = create(:country, name: "United States", iso: "US")
          zone.members.create(zoneable: united_states)
          promotion.rules << rule
          promotion.save!
        end

        it "returns available promotion if eligible promotions are available" do
          result = subject.eligible_promotion
          expect(result.eligible?).to eq true
          expect(result.amount).to eq(100)
        end

        context "when eligible promotions are not available" do
          let(:preferred_attributes) do
            { "0" => { "EUR" => { "amount" => "120", "enabled" => "true" } } }
          end

          it "does not return a promotion" do
            promo = subject.eligible_promotion
            expect(promo.eligible?).to eq false
            expect(promo.amount).to eq(0)
          end
        end

        context "when country is not found" do
          subject { described_class.new("FOOBAR", "USD") }

          it "does not return a promotion" do
            promo = subject.eligible_promotion
            expect(promo.eligible?).to eq false
            expect(promo.amount).to eq(0)
          end
        end
      end

      context "when no free shipping rules are found" do
        it "does not return a promotion" do
          promo = subject.eligible_promotion
          expect(promo.eligible?).to eq false
          expect(promo.amount).to eq(0)
        end
      end

      context "when there are available promotions" do
        let(:preferred_attributes) do
          {
            # not within the zones of interest
            "1" => { "USD" => { "amount" => "120", "enabled" => "true" } },
            # not enabled
            "2" => { "USD" => { "amount" => "100" } },
            # eligible, but lower amount
            "3" => { "USD" => { "amount" => "90", "enabled" => "true" } },
            # eligible, but lower amount
            "4" => { "USD" => { "amount" => "80", "enabled" => "true" } }
          }
        end

        before do
          allow(subject).to receive(:promotion).and_return(promotion)
          allow(subject).to receive(:user_zone_ids).and_return([2, 3, 4])
          allow(subject).to receive(:conditions).and_return(
            preferred_attributes
          )
        end

        # Please note it returns the first eligible amount rather than the
        # lowest, this probably needs to be fixed
        it "returns an Item object with the amount and eligible?: true" do
          promo = subject.eligible_promotion
          expect(promo.eligible?).to eq true
          expect(promo.amount).to eq(90)
        end
      end

      context "when there are no eligible promotions" do
        let(:preferred_attributes) do
          {
            # not within the zones of interest
            "1" => { "USD" => { "amount" => "120", "enabled" => "true" } },
            # not enabled
            "2" => { "USD" => { "amount" => "100" } }
          }
        end

        before do
          allow(subject).to receive(:user_zone_ids).and_return([2, 3, 4])
          allow(subject).to receive(:rules).and_return(preferred_attributes)
        end

        it "return an object with the amount set to 0 and eligible?: false" do
          promo = subject.eligible_promotion
          expect(promo.eligible?).to eq false
          expect(promo.amount).to eq(0)
        end
      end
    end
  end
end
