module Spree
  class CreateAndAllocateConsignmentService < Mutations::Command

    required do
      integer :order_id
    end

    def execute
      order = Spree::Order.find(order_id)
      return unless valid_consignment?(order)
      response = Metapack::Client.create_and_allocate_consignment_with_booking_code(allocation_hash(order))
      order.update_attributes!(order_attrs(response))
      update_parcels(order, response[:tracking])
      if order.metapack_allocated
        mark_order_as_shipped(order)
        Metapack::Client.create_labels_as_pdf(response[:metapack_consignment_code])
      else
        msg = "Cannot print Shipping Label for Consignment '#{response[:metapack_consignment_code]}' with status #{response[:metapack_status]}"
        add_error(:metapack, :metapack_allocation_error, msg)
      end

    rescue Exception => error
      Rails.logger.info '-'*80
      Rails.logger.info error.inspect
      Rails.logger.info error.backtrace

      add_error(:metapack, :metapack_error, error.inspect)
    end

    private
    def allocation_hash(order)
      {
        value:         order.item_normal_total,
        weight:        order.weight.round(2),
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
        terms_of_trade_code: terms_of_trade_code(order),
        booking_code:  booking_code(order)
      }
    end

    def terms_of_trade_code(order)
      if order.item_normal_total >= 300 && shipping_to_canada_or_usa(order)
        # duty paid by watg
        'DDP'
      else
        # duty unpaid
        'DDU'
      end
    end

    def shipping_to_canada_or_usa(order)
      (Spree::Country.where(iso: ['CA', 'US']).to_a).include?(order.ship_address.country)
    end

    def parcel(parcels, total_weight)
      total = parcels.size
      weight = (total_weight / total).round(2)
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
      if addr.address2.blank?
        {
          line1:    addr.address1,
          line2:    addr.city,
          postcode: addr.zipcode,
          country:  addr.country.iso3,
        }
      else
        {
          line1:    addr.address1,
          line2:    addr.address2,
          line3:    addr.city,
          postcode: addr.zipcode,
          country:  addr.country.iso3,
        }
      end
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
        metapack_allocated:        (hash[:metapack_status] == 'Allocated')
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

    def booking_code(order)
      li_by_product_type = order.line_items.map {|li|
        li.variant.product.product_type == 'pattern'
      }
      has_only_pattern = li_by_product_type.inject(true) {|res, a| res && a }
      less_than_ten =( li_by_product_type.select {|e| e }.size < 11)
      b_code = "@" + ((has_only_pattern && less_than_ten) ? 'PATTERN' : Spree::Zone.match(order.ship_address).name.upcase)
      b_code
    end

  end
end
