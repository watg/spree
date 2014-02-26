require 'spec_helper'

describe Spree::ProductPageVariant do

  describe "touching" do
    let(:product_page) { create(:product_page) }
    let(:variant) { create(:variant) }
    subject { create(:product_page_variant, product_page: product_page, variant: variant) }

    before { Timecop.freeze }
    after { Timecop.return }

    it "touches product_page but not variant" do
      subject.variant.update_column(:updated_at, 1.month.ago)
      subject.product_page.update_column(:updated_at, 1.month.ago)
      subject.touch
      expect(variant.reload.updated_at).to be_within(1.seconds).of(1.month.ago)
      expect(product_page.reload.updated_at).to be_within(1.seconds).of(Time.now)
    end

  end

end
