# -*- coding: utf-8 -*-
module ApplicationHelper
  include Spree::ProductsHelper
  include Spree::BaseHelper
  include Spree::CdnHelper
  include Spree::OrdersHelper

  def present(object, klass = nil)
    klass ||= "#{object.class}Presenter".constantize
    presenter = klass.new(object, self)
    yield presenter if block_given?
    presenter
  end

  def tracker_id
    @tracker_id ||= (YAML.load_file(File.join(Rails.root, 'config/ga.yaml'))[Rails.env])['tracker_id'] 
  end

  def production_or_staging?
    Rails.env.production? or Rails.env.staging?
  end

  def product_variant_options_path(variant)
    variant_option_values = variant.option_values.order('option_type_id ASC').map { |ov| ov.name }.join('/')  
    params = {
      controller:    'spree/products',
      action:        :show,
      id:            variant.product.slug
    }
    
    "#{url_for(params)}/#{variant_option_values}"
  end

  def path_to_variant(line_item, variant)
    pp = line_item.product_page
    unless pp
      pp = Spree::ProductPage.unscoped.find_by_id line_item.product_page_id
    end
    permalink = (pp ? pp.permalink : 'not-found')


    tab = line_item.product_page_tab
    unless tab
      tab = Spree::ProductPageTab.unscoped.find_by_id line_item.product_page_tab_id
    end

    safe_tab = ( tab ? tab.url_safe_tab_type : '') 

    spree.product_page_path(id: permalink, tab: safe_tab, variant_id: variant.id)
  end

  def image_url(product,style)
    if product.is_a?(Spree::Product) || product.is_a?(Spree::Variant)
      product_image_url(product, style)
    else
      image_image_url(product, style)
    end
  end


  def product_image_url(product, style)
    if product.images.empty?
      cdn_url("noimage/#{style}.png")
    else
      image = product.images.first
      image.attachment.url(style)
    end
  end

  def variant_image_url(variant, style)
    if variant.images.empty?
      product_image_url( variant.product, style )
    else
      image = variant.images.first
      image.attachment.url(style)
    end
  end

  def image_image_url(image, style)
    if image.blank?
      cdn_url("noimage/#{style}.png")
    else
      image.attachment.url(style)
    end
  end

  
end
