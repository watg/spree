require 'spec_helper'
require 'email_spec'

describe Spree::ShipmentMailer, :type => :mailer do
  include EmailSpec::Helpers
  include EmailSpec::Matchers

  let(:shipment) do
    product = stub_model(Spree::Product, :name => %Q{The "BEST" product})
    variant = stub_model(Spree::Variant, :product => product)
    line_item = stub_model(Spree::LineItem, :variant => variant, :order => order, :quantity => 1, :price => 5)
    shipment = stub_model(Spree::Shipment)
    allow(shipment).to receive_messages(:line_items => [line_item], :order => order)
    allow(shipment).to receive_messages(:tracking_url => "TRACK_ME")
    shipment
  end

  let(:order) { stub_model(Spree::Order) }

  context ":from not set explicitly" do
    it "falls back to spree config" do
      message = Spree::ShipmentMailer.shipped_email(shipment)
      expect(message.from).to eq([Spree::Config[:mails_from]])
    end
  end

  # Regression test for #2196
  it "doesn't include out of stock in the email body" do
    shipment_email = Spree::ShipmentMailer.shipped_email(shipment)
    expect(shipment_email.body).not_to include(%Q{Out of Stock})
  end

  it "shipment_email accepts an shipment id as an alternative to an Shipment object" do
    expect(Spree::Shipment).to receive(:find).with(shipment.id).and_return(shipment)
    expect {
      shipped_email = Spree::ShipmentMailer.shipped_email(shipment.id)
    }.not_to raise_error
  end

  describe '#kit_and_pattern_survey_email' do
    let(:email)    { described_class.kit_and_pattern_survey_email(order) }
    let(:order)    { create(:order) }
    let(:subject)  { %[Order Number #{order.number}, Your feedback on the knitting experience]}
    let(:header)   { JSON.load(email.header['X-MC-MergeVars'].to_s) }
    let(:tags)     { %[kits and patterns order survey] }
    let(:template) { %[en_kits_and_patterns_survey] }

    it { expect(email.subject).to eq subject }
    it { expect(email.header['X-MC-Tags'].to_s).to eq tags }
    it { expect(email.header['X-MC-Template'].to_s).to eq template }
    it { expect(header["name"]).to eq order.bill_address.full_name }
  end

  context "emails must be translatable" do
    context "shipped_email" do
      context "pt-BR locale" do
        before do
          I18n.enforce_available_locales = false
          pt_br_shipped_email = { :spree => { :shipment_mailer => { :shipped_email => { :dear_customer => 'Caro Cliente,' } } } }
          I18n.backend.store_translations :'pt-BR', pt_br_shipped_email
          I18n.locale = :'pt-BR'
        end

        after do
          I18n.locale = I18n.default_locale
          I18n.enforce_available_locales = true
        end

        specify do
          shipped_email = Spree::ShipmentMailer.shipped_email(shipment)
          expect(shipped_email).to have_body_text("Caro Cliente,")
        end
      end
    end
  end
end
