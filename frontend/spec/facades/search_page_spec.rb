require "spec_helper"

describe SearchPage do
  let(:context) do
    {
      device: :tablet,
      currency: "USD"
    }
  end

  subject { described_class.new(context) }

  [:params, :suites, :currency].each do |method|
    it { is_expected.to respond_to(method) }
  end
end
