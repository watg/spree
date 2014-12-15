module Spree

  class CreateAndAllocateConsignmentService < ActiveInteraction::Base

    integer :order_id

    def execute
      order = Spree::Order.find(order_id)
      return unless valid_consignment?(order)

      shipping_manifest = compose(Spree::ShippingManifestService, order: order)

      # Do not be tempted to rescue the whole block as it breaks the way compose propogates
      # errors
      begin
        response = Metapack::Client.create_and_allocate_consignment_with_booking_code(allocation_hash(order, shipping_manifest))
        order.update_attributes!(order_attrs(response))
        update_parcels(order, response[:tracking])
        if order.metapack_allocated
          mark_order_as_shipped(order)
          Metapack::Client.create_labels_as_pdf(response[:metapack_consignment_code])
        else
          msg = "Cannot print Shipping Label for Consignment '#{response[:metapack_consignment_code]}' with status #{response[:metapack_status]}"
          errors.add(:metapack, msg)
        end

      rescue Exception => error
        Helpers::AirbrakeNotifier.delay.notify(error)

        Rails.logger.info '-'*80
        Rails.logger.info error.inspect
        Rails.logger.info error.backtrace

        errors.add(:metapack, error.inspect)
      end
    end

    private
    def allocation_hash(order, shipping_manifest)

      consignment_value = shipping_manifest[:order_total]
      {
        value:         consignment_value,
        currency:      order.currency,
        currencyRate:  currencyRateToGBP(order.currency),
        weight:        order.weight.round(2),
        max_dimension: order.max_dimension.to_f,
        order_number:  order.number,
        parcels:       parcel(order, order.parcels, order.weight, shipping_manifest),
        recipient: {
          address:     address(order.shipping_address),
          phone:       order.shipping_address.phone,
          email:       order.email,
          firstname:   order.shipping_address.firstname,
          lastname:    order.shipping_address.lastname,
          name:        order.shipping_address.full_name
        },
        terms_of_trade_code: shipping_manifest[:terms_of_trade_code],
        booking_code:  order.shipments.first.shipping_method.metapack_booking_code
      }
    end

    def parcel(order, parcels, total_weight, shipping_manifest)
      total = parcels.size
      weight = (total_weight / total).round(2)
      value = (shipping_manifest[:order_total] / total).round(2)
      parcels.map.with_index do |p,index|
        {
          reference: p.id,
          height: p.height.to_f,
          value:  value,
          depth:  p.depth.to_f,
          width:  p.width.to_f,
          weight: weight.to_f,
          products: products(shipping_manifest)
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
        errors.add(:consignment, "Order needs at least one parcel to create consignment")
        return false
      end

      if order.shipped?
        errors.add(:consignment, "A consignment has already been created")
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

    def products(shipping_manifest)
      unique_products = shipping_manifest[:unique_products]

      # do something about digital , gift_cards
      unique_products.map do |line|
        product = line[:product]
        group = line[:group]
        country = line[:country]
        {
          origin: country.iso,
          fabric: group.contents,
          harmonisation_code: group.code,
          description: group.fabric,
          type_description: group.garment,
          weight: product.weight.to_f,
          total_product_value: line[:total_price].to_f,
          product_quantity: line[:quantity]
        }
      end
    end

    def currencyRateToGBP(currency)
      Helpers::CurrencyConversion::TO_GBP_RATES[currency].to_f
    end

  end
end
