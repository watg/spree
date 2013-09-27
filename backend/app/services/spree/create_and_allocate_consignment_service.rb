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
        parcels:       parcel(order.parcels, order.weight),
        recipient: {
          address:     address(order.shipping_address),
          phone:       order.shipping_address.phone,
          email:       order.email,
          name:        order.shipping_address.full_name
        },
      }
    end

    def parcel(parcels, total_weight)
      total = parcels.size
      weight = '%0.2f' % (total_weight / total)
      parcels.map.with_index do |p,index|
        {
          height: p.box.height.to_f,
          depth:  p.box.depth.to_f,
          width:  p.box.width.to_f,
          weight: weight.to_f
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
