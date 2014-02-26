require 'spec_helper'

describe "Metapack" do
  describe "Variant weight" do

    context "for product" do
      subject { create(:variant, weight: 12.0) }
      its(:weight) { should == 12.0 }
    end

    context "for kit" do
      subject { create(:variant, weight: 12.0, parts: [ create(:part, weight: 5.0)] ) }
      its(:weight) { should == 5.0 }
    end

  end
end