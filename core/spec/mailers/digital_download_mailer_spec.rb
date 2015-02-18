require 'spec_helper'

describe Spree::DigitalDownloadMailer do
  describe "#send_links" do
    let(:order) { create(:order_with_line_items) }

    subject(:email) { Spree::DigitalDownloadMailer.send_links(order) }

    it "sets the subject" do
      create(:store)
      subject = "Spree Test Store Digital Pattern Download ##{order.number}"
      expect(email.subject).to eq(subject)
    end

    it "sets the to address" do
      expect(email.to).to eq([order.email])
    end

    it "sets the from address" do
      from_address = "info@watg.com"
      Spree::Config[:mails_from] = from_address
      expect(email.from).to eq([from_address])
    end

    it "has an empty body" do
      expect(email.body).to be_blank
    end

    it "sets the mandrill template" do
      expect(email["X-MC-Template"].value).to eq("en_digital_downloads")
    end

    it "sets the mandrill tags" do
      expect(email["X-MC-Tags"].value).to eq("order, downloads")
    end

    it "sets the template language" do
      expect(email["X-MC-MergeLanguage"].value).to eq("handlebars")
    end

    describe "X-MC-MergeVars" do
      let(:line_item) { order.line_items.first }
      let(:variant) { line_item.variant }
      let(:digital) { Spree::Digital.create!(variant: variant) }

      subject(:merge_vars) { JSON.parse(email["X-MC-MergeVars"].value) }

      it "includes link to digital downloads" do
        link = Spree::DigitalLink.create!(line_item: line_item, digital: digital)
        download = merge_vars["downloads"].first
        expect(download["url"]).to eq("http://www.example.com/digital/#{link.secret}")
        expect(download["name"]).to eq(variant.name)
      end

      it "sets 'multiple' to false" do
        Spree::DigitalLink.create!(line_item: line_item, digital: digital)
        multiple = merge_vars["multiple"]
        expect(multiple).to eq false
      end

      context "when there is more than one digital download" do
        let(:other_line_item) { order.line_items.last }

        it "sets 'multiple' to true" do
          Spree::DigitalLink.create!(line_item: line_item, digital: digital)
          other_digital = Spree::Digital.create!(variant: other_line_item.variant)
          Spree::DigitalLink.create!(line_item: other_line_item, digital: other_digital)

          multiple = merge_vars["multiple"]
          expect(multiple).to eq true
        end
      end
    end
  end
end
