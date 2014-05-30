require 'spec_helper'

describe Spree::CreateAndAllocateConsignmentService do
  subject { Spree::CreateAndAllocateConsignmentService }
  let(:order) { FactoryGirl.create(:order_ready_to_be_consigned_and_allocated, line_items_count: 1) }
  let(:country) { create(:country) }
  let!(:shipping_method) { create(:shipping_method, shipments: order.shipments) }

  before do
    Spree::ProductGroup.any_instance.stub(:country).and_return country
  end

  describe "::run" do
    let(:response) { {
        metapack_consignment_code: '12345',
        tracking: [{reference: order.parcels[0].id, metapack_tracking_code: '000023', metapack_tracking_url: 'http://carrier.com/tracking/000023'},
                   {reference: order.parcels[1].id, metapack_tracking_code: '000045', metapack_tracking_url: 'http://carrier.com/tracking/000045'} ],
        metapack_status: 'Allocated'} }

    before do
      allow(Metapack::Client).to receive(:create_and_allocate_consignment_with_booking_code).and_return(response)
      allow(Metapack::Client).to receive(:create_labels_as_pdf).with('12345').and_return(:pdf)
      @outcome = subject.run(order_id: order.id)
      order.reload
    end

    context "successfull case" do
      it "service outcome is positive" do
        expect(@outcome).to be_true
      end

      it "updates order with metapack consignment code" do
        expect(order.metapack_allocated).to be_true
        expect(order.metapack_consignment_code).to eql('12345')
      end

      it "updates parcels tracking details" do
        p1 = order.parcels[0]
        expect(p1.metapack_tracking_code).to eq('000023')
        expect(p1.metapack_tracking_url).to  eq('http://carrier.com/tracking/000023')
      end

      it "marked the order as shipped" do
        expect(order).to be_shipped
      end
    end

    context "failed case" do
      it "cannot create consignment when order has no parcel" do
        order_no_parcel = FactoryGirl.create(:order_ready_to_ship)
        outcome = subject.run(order_id: order_no_parcel.id)
        expect(outcome.success?).to be_false
      end

      it "order is already shipped" do
        shipped_order = FactoryGirl.create(:shipped_order)
        outcome = subject.run(order_id: shipped_order.id)
        expect(outcome.success?).to be_false
      end
    end

    it "returns the label PDF" do
      expect(@outcome.result).to eq(:pdf)
    end

  end

  context "#allocation_hash" do
    let(:consignment) { Spree::CreateAndAllocateConsignmentService.new }
    let(:product_group) { create(:product_group, origin: "UK", fabric: "Knitted", code: "CODE123", contents: "10% Wool 90% Cotton", garment: "Sweater") }

    before do
      order.line_items.first.product.update_column(:product_group_id, product_group.id)
    end

    before do
      shipping_method.metapack_booking_code = '@GLOBALZONE'
      shipping_method.save
    end

    it "builds all data necessary to create consignment allocation on metapack" do
      variants_weight = order.line_items.map{ |li| li.variant.weight * li.quantity }.sum
      parcel_weight = (order.weight / order.parcels.size).round(2)

      p1,p2 = [order.parcels[0],order.parcels[1]]
      address = { line1: "10 Lovely Street", line2: "Northwest", line3: "Herndon", postcode: "20170", country: "USA" }
      consignment_value = order.total * Helpers::CurrencyConversion::TO_GBP_RATES[order.currency]
      parcel_value = consignment_value / 2
      expected  = {
        value:         consignment_value,
        weight:        ( variants_weight.to_f + 0.6 ).round(2),
        max_dimension: 40.0,
        order_number:  order.number,
        parcels:       [
                        {
                          reference: p1.id, 
                          height: p1.height.to_f, 
                          value: parcel_value,
                          depth: p1.depth.to_f, 
                          width: p1.width.to_f,  
                          weight: parcel_weight,
                          products: [
                            {
                            :origin=> country.iso, 
                            :fabric=>"10% Wool 90% Cotton",
                            :harmonisation_code=>"CODE123",
                            :description=>"Knitted",
                            :type_description =>"Sweater",
                            :weight=>0.25,
                            :total_product_value=>10.0,
                            :product_quantity=>1
                            }
                          ]
                        },
                        {
                          reference: p2.id, 
                          height: p2.height.to_f, 
                          value: parcel_value,
                          depth: p2.depth.to_f, 
                          width: p2.width.to_f,  
                          weight: parcel_weight,
                          products: [
                            {
                            :origin=> country.iso, 
                            :fabric=>"10% Wool 90% Cotton",
                            :harmonisation_code=>"CODE123",
                            :description=>"Knitted",
                            :type_description =>"Sweater",
                            :weight=>0.25,
                            :total_product_value=>10.0,
                            :product_quantity=>1
                            }
                          ]
                        }
                       ],
        recipient: {
          address:   address,
          phone:     "123-456-7890",
          email:     order.email,
          firstname: "John",
          lastname:  "Doe",
          name:      "John Doe"
        },
        terms_of_trade_code: 'DDP',
        booking_code: '@GLOBALZONE',
      }

      expect(consignment.send(:allocation_hash, order)).to eql(expected)

      order.shipping_address.update_attributes(address2: nil)
      address = { line1: "10 Lovely Street", line2: "Herndon", postcode: "20170", country: "USA" }
      expected[:recipient][:address] = address
      expect(consignment.send(:allocation_hash, order)).to eql(expected)
    end

  end
end
