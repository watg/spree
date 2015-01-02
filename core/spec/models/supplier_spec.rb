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

  context "is_company" do

    it "is false by default" do
      expect(supplier.is_company).to be false
    end

  end

  context "is_displayable" do

    it "is true by default" do
      expect(supplier.is_displayable).to be true
    end

  end

  context "name" do
    context "validation" do
      let(:supplier) { Spree::Supplier.new(permalink: "something", is_company: is_company) }

      context "for a company" do
        let(:is_company) { true }

        it "is invalid when company name is blank" do
          expect(supplier).not_to be_valid
          expect(supplier.errors.messages).to have_key(:company_name)
          expect(supplier.errors.messages).not_to have_key(:firstname)
          expect(supplier.errors.messages).not_to have_key(:lastname)
        end

        it "is invalid when company name is blank but fullname given" do
          supplier.firstname = "Some"
          supplier.lastname = "Supplier"
          expect(supplier).not_to be_valid
        end

        it "is valid if company name is given" do
          supplier.company_name = "Company"
          expect(supplier).to be_valid
        end
      end

      context "for an individual" do
        let(:is_company) { false }

        it "is invalid when fullname is blank" do
          expect(supplier).not_to be_valid
          expect(supplier.errors.messages).not_to have_key(:company_name)
          expect(supplier.errors.messages).to have_key(:firstname)
          expect(supplier.errors.messages).to have_key(:lastname)
        end

        it "is invalid when fullname is blank but company name given" do
          supplier.company_name = "Company"
          expect(supplier).not_to be_valid
        end

        it "is valid if firstname is given" do
          supplier.firstname = "Some"
          expect(supplier).to be_valid
        end

        it "is valid if lastname is given" do
          supplier.lastname = "Supplier"
          expect(supplier).to be_valid
        end
      end
    end

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
