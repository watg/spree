require 'spec_helper'

def consignment_hash
      {
        value:         1.2,
        currency:      "USD",
        currencyRate:  1.5,
        weight:        1.0,
        max_dimension: 30.0,
        order_number:  'order1',
        parcels:       [
                        {
                          reference: 1,
                          height: 10.0,
                          value:  1.2,
                          depth: 20.0,
                          width: 30.0,
                          weight: 1.0,
                          products: [{
                            origin: 'UK',
                            fabric: '50% Cotton 50% Wool',
                            harmonisation_code: 'CODE012',
                            description: "Knitted",
                            type_description: "Sweater",
                            weight: 0.2,
                            total_product_value: 23.17,
                            product_quantity: 5
                          }]
                        }
                       ],
        recipient: {
          address: {
            line1: "10 Lovely & Wonderful Street",
            line2: "Northwest",
            line3: "Herdon",
            postcode:"20170",
            country: "GBR"},
          phone:       "123-456-7890",
          email:        'john@doe.com',
          firstname:   "John",
          lastname:    "Doe",
          name:        "John Doe"
        },
        terms_of_trade_code: 'DDU',
        booking_code: "PARCEL",
       }
end

describe "Erb Template" do
  describe :create_and_allocate_consignment_with_booking_code do
    subject { Metapack::SoapTemplate.new(:create_and_allocate_consignments_with_booking_code, consignment: consignment_hash) }
    its(:xml) { should eq(xml_fixture('create_and_allocate_consignments_with_booking_code.xml')) }
  end

  describe :create_labels_as_pdf do
    subject { Metapack::SoapTemplate.new(:create_labels_as_pdf, consignment_code: 12345) }
    its(:xml) { should eq(xml_fixture('create_labels_as_pdf.xml')) }
  end

  
  def xml_fixture(file)
    File.read(File.join(fixture_path, "xml", file)) 
  end
end
