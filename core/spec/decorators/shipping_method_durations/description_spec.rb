require "spec_helper"
describe ShippingMethodDurations::Description do
  context "with holidays" do
    let(:shipping_method_duration) { build_stubbed(:shipping_method_duration, min: 3, max:4) }
    subject         { shipping_method_duration.extend(described_class) }
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
      Timecop.freeze(Time.local(2015))
    end

    describe ".static_description" do
      it{ expect(subject.static_description).to eq "3-4 business days" }
    end

    describe ".dynamic_description" do
      it{ expect(subject.dynamic_description).to eq "4-6 business days" }
    end

    context 'without a min value' do
      let(:shipping_method_duration) {build_stubbed(:shipping_method_duration, min: nil , max: 4 )}
      subject         { shipping_method_duration.extend(described_class) }
      describe ".description" do
        it { expect(subject.static_description).to eq("up to 4 business days") }
      end
    end

    context 'without a max value' do
      let(:shipping_method_duration) {build_stubbed(:shipping_method_duration, min: 4 , max: nil )}
      subject         { shipping_method_duration.extend(described_class) }
      describe ".description" do
        it { expect(subject.static_description).to eq("in a few days") }
      end
    end

    context 'without a max or a min value' do
      let(:shipping_method_duration) {build_stubbed(:shipping_method_duration, min: nil , max: nil)}
      subject         { shipping_method_duration.extend(described_class) }
      describe ".description" do
        it { expect(subject.static_description).to eq("in a few days") }
      end
    end

    context 'with a max and a min value' do
      let(:shipping_method_duration) {build_stubbed(:shipping_method_duration, min: 3 , max: 4 )}
      subject         { shipping_method_duration.extend(described_class) }
      describe ".description" do
        it { expect(subject.static_description).to eq("3-4 business days") }
      end
    end

  end
end
