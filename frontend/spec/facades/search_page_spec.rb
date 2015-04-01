require "spec_helper"
require_relative "../modules/indexable_shared_examples"

describe SearchPage do
  let(:context) do
    {
      device: :tablet,
      currency: "USD"
    }
  end

  subject { described_class.new(context: context) }

  # TODO
  it_behaves_like Indexable
end
