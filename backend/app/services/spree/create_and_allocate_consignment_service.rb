module Spree
  class CreateAndAllocateConsignmentService < Mutations::Command

    required do
      integer :order_id
    end

    def execute
      order = Spree::Order.find(order_id)
      response = Metapack::Client.create_and_allocate_consignment(allocation_hash(order))
      order.update_attributes!(response)
    rescue Exception => error

      Rails.logger.info '-'*80
      Rails.logger.info error.inspect
      Rails.logger.info error.backtrace

      add_error(:metapack, :metapack_error, error.inspect)
    end

    private
    def allocation_hash(order)
      {
        value:         order.value_in_gbp,
        weight:        order.weight,
        max_dimension: order.max_dimension.to_f,
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
          height: p.box.height,
          depth:  p.box.depth,
          width:  p.box.width,
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
