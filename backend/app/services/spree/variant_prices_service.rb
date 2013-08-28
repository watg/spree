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

      update_variant_sale(params[:product],params[:variant_in_sale_ids])
      
      controller.send(:create_callback, errors)
    end

    private
    def update_variant_sale(product, variant_ids)
      Spree::Variant.where(product_id: product.id).update_all(in_sale: false, updated_at: Time.now)
      Spree::Variant.where(id: variant_ids).update_all(in_sale: true, updated_at: Time.now)
      product.touch # this is here to invalidate the cache set on taxon through product 
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
