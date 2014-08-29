require 'spec_helper'

describe Spree::Supplier do

  let(:supplier) { create(:supplier, nickname: 'foo', firstname: "Dave", lastname: "Dawson") }

  it "generates permalinks" do
    supplier1 = create(:supplier, firstname: "Queen", lastname: "Knitter 1", permalink: nil)
    supplier2 = create(:supplier, firstname: "Queen", lastname: "Knitter 2", permalink: nil)
    supplier3 = create(:supplier, firstname: "Queen Marry", lastname: "Knitter 3", permalink: nil)

    expect(supplier1.permalink).to eq "queen-knitter-1"
    expect(supplier2.permalink).to eq "queen-knitter-2"
    expect(supplier2.permalink).to eq "queen-knitter-2"
    expect(supplier3.permalink).to eq "queen-marry-knitter-3"
  end

  context "name" do
    it "returns the name" do
      expect(supplier.name).to eq "Dave Dawson"
    end

    context "is_company" do

      before do
        supplier.is_company = true
        supplier.company_name = 'WATG'
      end

      it "returns company name" do
        expect(supplier.name).to eq "Company: WATG [Dave Dawson]"
      end

    end
  end

end
