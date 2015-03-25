require "spec_helper"
describe Spree::Api::Dashboard::Office::FormatLastBoughtProduct, type: :interaction do
  let!(:old_product) { create(:product, :with_marketing_type, name: "old_product") }
  let!(:new_product) { create(:product, :with_marketing_type, name: "new_product") }

  let!(:new_variant) { create(:variant, product: new_product) }
  let!(:old_variant) { create(:variant, product: old_product) }

  let!(:new_order) do
    create(:order, completed_at: Time.zone.now, variants: [new_variant], state: "complete")
  end
  let!(:old_order) do
    create(:order, completed_at: Time.zone.yesterday, variants: [new_variant], state: "complete")
  end

  subject { described_class.new(Spree::Order.complete) }
  describe "execute" do
    it "returns the last variant bought" do
      expect(subject.run).to eq(

                                 name: new_product.name,
                                 marketing_type: new_product.marketing_type.title,
                                 image_url: nil

                             )
    end
  end
end
