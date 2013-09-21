module Spree
  class CreateAndAllocateConsignmentService < Mutations::Command

    required do
      integer :order_id
    end
    
    def execute
      order = Spree::Order.find(order_id)
      response = metapack_client.create_and_allocate_consignment(allocation_hash(order))
      order.update_attributes!(response)
    rescue Exception => error
      
      Rails.logger.info '-'*80
      Rails.logger.info error.inspect
      Rails.logger.info error.backtrace
      
      add_error(:metapack, :metapack_error, error.inspect)
    end

    private
    def metapack_client
      @metapack_client ||= Metapack::Client.new
    end
    def allocation_hash(order)
      { 
        value:         order.value_in_gbp,
        weight:        order.weight,
        max_dimension: order.max_dimension.to_i,
        order_number:  order.number,  
        parcels:       parcel(order.parcels),
        recipient: {
          address:     address(order.shipping_address),
          phone:       order.shipping_address.phone,
          email:       order.email,
          name:        order.shipping_address.full_name
        },
        special_instructions: "",
      }
    end

    def parcel(parcels)
      total = parcels.size
      parcels.map.with_index do |p,index|
        {
          height: p.box.height.to_i,
          depth:  p.box.depth.to_i,
          width:  p.box.width.to_i,
          number: "#{index+1}/#{total}"
        }
      end
    end

    def address(addr)
      {
        line1:    [addr.address1, addr.address2].compact.join(', '),
        line2:    addr.city,
        postcode: addr.zipcode,
        country:  addr.country.iso3,
      }
    end
  end
end
