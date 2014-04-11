require 'spec_helper'

describe Spree::OrderDecorator, type: :decorator do
  include Draper::ViewHelpers
  let(:order) { create(:order)}
  subject { order.decorate }
  let!(:linkshare_params) { subject.linkshare_params }

  it "linkshare have params" do
    expect(linkshare_params.keys).to match_array([:mid, :ord, :cur, :skulist, :qlist, :amtlist, :namelist])
  end

  describe "list params values" do
  let(:variants)    {create_list(:variant,2)} 
  let(:line_items)  {[build(:line_item, order: order, quantity: 2, price: 15, variant: variants.first),
                      build(:line_item, order: order, quantity: 1, price: 7.99, variant: variants.last)]}
  let(:adjustments)  {[build(:adjustment, order: order, amount: -12.50, label: "My Super discount", source_type: "Spree::PromotionAction", source_id: 1)]}

  before do
    subject.stub(:line_items).and_return(line_items)
    order.stub(:item_total).and_return(2)
    subject.stub(:discounts).and_return(adjustments)
  end

    it "skulist" do
      expected = variants.map(&:number) + [adjustments.first.label.gsub(" ","-")]
      expect(subject.skulist).to match_array(expected)
    end

    it "qlist" do
      expected  = line_items.map(&:quantity) + [0]
      expect(subject.qlist).to match_array(expected)
    end

    it "amtlist" do
      expected = [3000, 799, -1250]
      expect(subject.amtlist).to match_array(expected)
    end

    it "namelist" do
      expected = variants.map{|e| "#{URI.escape(e.name)}-#{e.number}" } + [URI.escape(adjustments.first.label)]
      expect(subject.namelist).to match_array(expected)
    end

  end
end
