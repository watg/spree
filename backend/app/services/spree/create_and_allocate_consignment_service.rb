module Spree
  class CreateAndAllocateConsignmentService < Mutations::Command

    required do
      integer :order_id
    end

    def execute
      order = Spree::Order.find(order_id)
      return unless valid_consignment?(order)
      response = Metapack::Client.create_and_allocate_consignment(allocation_hash(order))
      order.update_attributes!(order_attrs(response))
      update_parcels(order, response[:tracking])
      mark_order_as_shipped(order)   if order.metapack_allocated  
      Metapack::Client.create_labels_as_pdf(response[:metapack_consignment_code])

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
          firstname:   order.shipping_address.firstname,
          lastname:    order.shipping_address.lastname,
          name:        order.shipping_address.full_name
        },
      }
    end

    def parcel(parcels, total_weight)
      total = parcels.size
      weight = '%0.2f' % (total_weight / total)
      parcels.map.with_index do |p,index|
        {
          reference: p.id,
          height: p.height.to_f,
          depth:  p.depth.to_f,
          width:  p.width.to_f,
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

    def valid_consignment?(order)
      if order.parcels.blank?
        add_error(:consignment, :cannot_create_consignment, "Order needs at least one parcel to create consignment")
        return false
      end

      if order.shipped?
        add_error(:consignment, :consignment_already_created, "A consignment has already been created")
        return false
      end

      true
    end
    
    def order_attrs(hash)
      {
        metapack_consignment_code: hash[:metapack_consignment_code],
        metapack_allocated:        !hash[:tracking].blank?
      }
    end

    def update_parcels(order, hash)
      order.parcels.each do |parcel|
        attrs = hash.detect {|h| h[:reference].to_i == parcel.id }
        if attrs
          attrs.delete(:reference)
          parcel.update_attributes(attrs)
        end
      end
    end

    def mark_order_as_shipped(order)
      order.shipment_state = 'shipped'
      order.save(validate: false)
      order.shipments.map(&:ship)
    end
    
  end
end
