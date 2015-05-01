require "spec_helper"

describe Holidays::UKHolidays, type: :domains do
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
  context "is holidays in the range" do
    describe "#holidays_in" do
      it 'returns all the holidays in the range' do
        Timecop.freeze(Time.local(2015))
        expect(described_class.holidays_in(4).size).to eq 2
      end
      it 'returns all the holidays in the range' do
        Timecop.freeze(Time.local(2015))
        expect(described_class.holidays_in(3).size).to eq 1
      end
    end
  end

  context "no holidays in the range" do
    describe "#holidays_in" do
      it 'returns all the holidays in the range' do
        Timecop.freeze(Time.local(2015))
        expect(described_class.holidays_in(2).size).to eq 0
      end
    end
  end

  context "api is running fine" do
    describe "#holidays" do
      it "returns a list of public holidays" do
        expect(described_class.holidays.size).to eq 2
      end
    end
  end

  context "api is returning a error" do
    describe "#holidays" do
      it "returns [] if it raises an error" do
        allow(RestClient).to receive(:get).and_raise(RestClient::ResourceNotFound)
        expect(described_class.holidays).to eq []
      end
    end
  end
end
