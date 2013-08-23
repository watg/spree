module Spree
  class VariantPricesService < Struct.new(:controller)
    attr_reader :errors
    
    def perform(params)
      params[:vp].each do |variant_id, prices_by_type|
        variant = Spree::Variant.find(variant_id)
        
        prices_by_type.each do |type, prices|
          update_variant_prices(variant, type, prices)
        end
      end

      update_variant_sale(params[:variant_in_sale_ids])
      
      controller.send(:create_callback, errors)
    end

    private
    def update_variant_sale(variant_ids)
      Spree::Variant.update_all(in_sale: false)
      Spree::Variant.where(id: variant_ids).update_all(in_sale: true)
    end
    
    def update_variant_prices(v, t, p)
      controller.supported_currencies.each do |currency|
        o = v.price_for_type(t,currency.iso_code)
        o.price = (p[currency.iso_code].blank? ? nil : p[currency.iso_code])
        o.save if o.changed?
        add_error("#{v.options_text} #{t} price: #{o.errors.full_messages.join(', ')}") if o.errors.any?
      end
    end

    def add_error(msg)
      @errors ||= []
      @errors << msg
    end
      
  end
end
