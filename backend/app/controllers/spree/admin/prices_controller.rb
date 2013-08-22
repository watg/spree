module Spree
  module Admin
    class PricesController < ResourceController
      belongs_to 'spree/product', :find_by => :permalink

      def create
        errors = []
        params[:vp].each do |variant_id, prices|
          variant = Spree::Variant.find(variant_id)
          if variant
            supported_currencies.each do |currency|
              if variant.isa_part?
                kit_price = variant.kit_price_in(currency.iso_code)
                kit_price.price = (prices['kit_price'][currency.iso_code].blank? ? nil : prices['kit_price'][currency.iso_code])
                kit_price.save if kit_price.changed?
                if kit_price.errors.any?
                  errors << "Kit Price: #{kit_price.errors.full_messages.join(', ')}"
                end
              end
              price = variant.price_in(currency.iso_code)
              price.price = (prices[currency.iso_code].blank? ? nil : prices[currency.iso_code])
              price.save if price.changed?
              if price.errors.any?
                errors << "Price: #{price.errors.full_messages.join(', ')}"
              end
            end
          end
        end
                  
        flash[:error] = errors.join(', ') unless errors.blank?
        render :action => :index
      end
    end
  end
end
