require 'spec_helper'

describe Metapack::Config do
  subject { Metapack::Config }

  context "metapack active flag" do
    before do
      allow(ENV).to receive(:[]).with("METAPACK_ACTIVE").and_return("false")
    end
    its(:active) { should be_false }
  end
 
  context "when there is no heroku config" do
    its(:host) { should eq('test.metapack') }
    its(:service_base_url) { should eq('/dm/services') }
    its(:username) { should eq('test_username') }
    its(:password) { should eq('test_password') }
    its(:active)   { should be_true }
  end

  context "when the metapack details are set in heroku" do
    before :each do
      allow(ENV).to receive(:[]).with("METAPACK_USERNAME").and_return("mp_user")
      allow(ENV).to receive(:[]).with("METAPACK_PASSWORD").and_return("mp_password")
      allow(ENV).to receive(:[]).with("METAPACK_HOST").and_return("override.host")
      allow(ENV).to receive(:[]).with("METAPACK_SERVICE_BASE_URL").and_return("/override/dm/services")
    end

    its(:host) { should eq('override.host') }
    its(:service_base_url) { should eq('/override/dm/services') }
    its(:username) { should eq('mp_user') }
    its(:password) { should eq('mp_password') }
  end
end
