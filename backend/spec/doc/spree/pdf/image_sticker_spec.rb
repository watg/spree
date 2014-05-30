require 'spec_helper'

describe Spree::PDF::ImageSticker do

  describe "create" do
    let(:order) { create(:completed_order_with_totals) }

    subject { Spree::PDF::ImageSticker.new(order).create }
    it { should_not be_nil }
  end

end
