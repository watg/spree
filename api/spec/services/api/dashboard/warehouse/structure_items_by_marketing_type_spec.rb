require "spec_helper"

describe Api::Dashboard::Warehouse::StructureItemsByMarketingType, type: :interaction do
  let(:orders) do
    [
      OpenStruct.new(marketing_type_title: "t1", quantity: 2),
      OpenStruct.new(marketing_type_title: "t1", quantity: 2),
      OpenStruct.new(marketing_type_title: "t2", quantity: 1),
      OpenStruct.new(marketing_type_title: "t2", quantity: 1),
      OpenStruct.new(marketing_type_title: "t3", quantity: 6)
    ]
  end

  subject { described_class.new(orders) }
  describe "execute" do
    it "returns the correct ammount per marketing type ordered" do
      expect(subject.run[0]).to eq(["t3", 6])
      expect(subject.run[1]).to eq(["t1", 4])
      expect(subject.run[2]).to eq(["t2", 2])
    end
  end
end
