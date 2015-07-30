require "spec_helper"

describe Metapack::Config do
  subject { described_class }

  context "metapack active flag" do
    before do
      allow(ENV).to receive(:[]).with("METAPACK_ACTIVE").and_return("false")
    end

    describe "#active" do
      subject { super().active }
      it { is_expected.to be false }
    end
  end

  context "when there is no heroku config" do
    describe "#host" do
      subject { super().host }
      it { is_expected.to eq("test.metapack") }
    end

    describe "#service_base_url" do
      subject { super().service_base_url }
      it { is_expected.to eq("/dm/services") }
    end

    describe "#username" do
      subject { super().username }
      it { is_expected.to eq("test_username") }
    end

    describe "#password" do
      subject { super().password }
      it { is_expected.to eq("test_password") }
    end

    describe "#active" do
      subject { super().active }
      it { is_expected.to be true }
    end
  end

  context "when the metapack details are set in heroku" do
    before :each do
      allow(ENV).to receive(:[]).with("METAPACK_USERNAME").and_return("mp_user")
      allow(ENV).to receive(:[]).with("METAPACK_PASSWORD").and_return("mp_password")
      allow(ENV).to receive(:[]).with("METAPACK_HOST").and_return("override.host")
      allow(ENV).to receive(:[]).with("METAPACK_SERVICE_BASE_URL").and_return("/override/dm/services")
    end

    describe "#host" do
      subject { super().host }
      it { is_expected.to eq("override.host") }
    end

    describe "#service_base_url" do
      subject { super().service_base_url }
      it { is_expected.to eq("/override/dm/services") }
    end

    describe "#username" do
      subject { super().username }
      it { is_expected.to eq("mp_user") }
    end

    describe "#password" do
      subject { super().password }
      it { is_expected.to eq("mp_password") }
    end
  end
end
