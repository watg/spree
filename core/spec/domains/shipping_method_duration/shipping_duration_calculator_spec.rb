require "spec_helper"

module ShippingMethodDurations
  describe ShippingDurationCalculator do
    let(:shipping_method_duration)     { build_stubbed(:shipping_method_duration) }
    subject         { described_class.new(shipping_method_duration) }
    let(:response) do
      '{"england-and-wales":{"division":"england-and-wales",
        "events":[
        {"title":"New Year\u2019s Day","date":"2015-01-04","notes":"Substitute day","bunting":true},
        {"title":"Good Friday","date":"2015-01-05","notes":"","bunting":false}
        ]
        }}'
    end
    before do
      WebMock.stub_request(:get, "https://www.gov.uk/bank-holidays.json")
        .to_return(status: 200, body: response, headers: {})
    end
    context "with 2 holidays before the min delivery days" do
      before { shipping_method_duration.min = 3; shipping_method_duration.max = 5 }
      it "increases the min and the max value by 2" do
        Timecop.freeze(Time.local(2015))
        expect(subject.calc_min).to eq(4)
        expect(subject.calc_max).to eq(7)
      end
    end

    context "with holidays between the min and max delivery speculation" do
    end
  end
end
