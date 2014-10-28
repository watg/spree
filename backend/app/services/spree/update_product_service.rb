module Spree
  class UpdateProductService < Mutations::Command
    include ServiceTrait::Prices
    required do
      model :product, class: 'Spree::Product'
      duck  :details
      duck  :prices, nils: true
    end

    def execute
      visible_option_type_ids = details.delete(:visible_option_type_ids)
      ActiveRecord::Base.transaction do
        update_details(product, details.dup)
        update_prices(prices.dup, product.master)                 if prices
        option_type_visibility(product, visible_option_type_ids)  unless details.has_key?(:product_properties_attributes)
      end
    rescue Exception => e
      Rails.logger.error "[ProductUpdateService] #{e.message} -- #{e.backtrace}"
      add_error(:product_update, :exception, e.message)
    end

    def update_details(product, product_params)
      product_params[:option_type_ids] = split_params(product_params[:option_type_ids])

      update_before(product_params)

      update_outcome = product.update_attributes(product_params)
      if update_outcome == false or product.errors.any?
        add_error(:product, :details, product.errors.full_messages.join(', '))
      end
    end

    def split_params(input=nil)
      input.blank? ? [] : input.split(',').map(&:to_i)
    end


    def option_type_visibility(product, visible_option_type_ids)
      list = split_params(visible_option_type_ids)
      option_type_ids = product.option_types.map(&:id)

      reset_visible_option_types(product.id, (option_type_ids - list))
      update_visible_option_types(product.id, list)
    end

    private
    def update_visible_option_types(p_id, list)
      list.each {|ot_id|
        if pot = Spree::ProductOptionType.where(product_id: p_id, option_type_id: ot_id).first
          make_visible(pot)
        end
      }
    end
    def reset_visible_option_types(product_id, ids_to_reset)
      Spree::ProductOptionType.where(product_id: product_id, option_type_id: ids_to_reset).update_all(visible: false)
    end

    def make_visible(product_option_type)
      product_option_type.update_attributes(visible: true)
    end

    def update_before(params)
      # note: we only reset the product properties if we're receiving a post from the form on that tab
      return unless params[:clear_product_properties]
      params ||= {}
    end

  end
end
