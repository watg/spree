require 'spec_helper'

describe Spree::Feed::StockThresholdRequirement do
  subject(:threshold_requirement) { Spree::Feed::StockThresholdRequirement.new }

  describe "#list" do
    let(:v1) { create(:variant) }
    let(:v2) { create(:variant) }
    let(:v3) { create(:variant) }
    let(:location1) { create(:stock_location) }
    let(:location2) { create(:stock_location) }

    before do
      v1.stock_thresholds.create(stock_location: location1, value: 100)
      si = location1.stock_item(v1)
      si.send(:count_on_hand=, 98)
      si.save

      v2.stock_thresholds.create(stock_location: location1, value: 100)
      si = location1.stock_item(v2)
      si.send(:count_on_hand=, 99)
      si.save

      v1.stock_thresholds.create!(stock_location: location2, value: 10)
      si = location2.stock_item(v1)
      si.send(:count_on_hand=, 11)
      si.save

      location2.stock_item(v1).send(:count_on_hand=, 11)
      v2.stock_thresholds.create!(stock_location: location2, value: 10)
      si = location2.stock_item(v2)
      si.send(:count_on_hand=, 8)
      si.save
    end

    it "returns a mapping of {location => { variant => count }}" do
      expected = {
        location1 => {
          v1 => 2,
          v2 => 1,
        },
        location2 => {
          v2 => 2,
        }
      }

      expect(threshold_requirement.list).to eq(expected)
    end
  end
end
