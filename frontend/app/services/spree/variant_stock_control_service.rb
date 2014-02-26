module Spree
  class VariantStockControlService < Mutations::Command
      
    include ActionView::Helpers
    include ActionDispatch::Routing
    include Rails.application.routes.url_helpers
    
    required do
      duck :selected_variant
    end

    def execute
      recommendation = {redirect_to: nil}
      if selected_variant.out_of_stock? and !selected_variant.kit?
        nv  = next_variant(selected_variant) 
        if nv
          recommendation[:message]     = "The <b>#{variant_name(selected_variant)}</b> has been snapped up.<br/> Luckily we have another <b>#{variant_name(nv)}</b> knitted  by the Gang.".html_safe
          recommendation[:redirect_to] = product_variant_options_path(nv)
        else
          recommendation[:message]     = "Sorry! The <b>#{variant_name(selected_variant)}</b> has sold out. Check out our other knits made unique by the Gang.".html_safe
          recommendation[:redirect_to] = variant_taxon_path(selected_variant)
        end  
      end
      
      recommendation
    end

    private
    def next_variant(variant)
      nv = variant.product.next_variant_in_stock || variant.product.product_group.next_variant_in_stock
      nv
    end
    
    def product_variant_options_path(variant)
      variant_option_values = variant.option_values.order('option_type_id ASC').map { |ov| ov.name }.join('/')
      base_path = Spree::Core::Engine.routes.url_helpers.products_path(variant.product).gsub('.','/')
    
      "#{base_path}/#{variant_option_values}"
    end

    def variant_taxon_path(variant)
      taxon = variant.product.taxons.first
      Spree::Core::Engine.routes.url_helpers.nested_taxons_path(taxon)
    end

    def variant_name(variant)
      "#{variant.product.name} #{variant.options_text}"
    end

  end
end
