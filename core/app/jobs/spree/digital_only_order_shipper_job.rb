module Spree
  DigitalOnlyOrderShipperJob = Struct.new(:order) do
    
    def perform
      li_pn_list = order.line_items.map {|li| li.product_nature == 'digital'}
      order_have_only_digital_line_items = li_pn_list.inject(true) {|result, li_pn| result && li_pn} && (li_pn_list.size >= 1)

      if order_have_only_digital_line_items
        order.shipment_state = 'shipped'
        order.save(validate: false)
        order.shipments.map(&:ship)
      end
    end
  end
end
