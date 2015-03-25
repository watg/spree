require "spec_helper"
describe Spree::SimpleBasePresenter do
  let(:view_context) do
    double("view_context",
           device: "mobile",
           current_currency: "USD",
           current_country_code: "US"
          )
  end

  subject { described_class.new(view_context) }

  it "returns the device" do
    expect(subject.device).to eq view_context.device
  end

  it "returns the currency" do
    expect(subject.currency).to eq view_context.current_currency
  end

  it "returns the country_code" do
    expect(subject.country_code).to eq view_context.current_country_code
  end

  it "h returns the view_context" do
    expect(subject.send(:h)).to eq view_context
  end
end
