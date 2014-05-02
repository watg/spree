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
    t = (line_item.target ? line_item.target.id : nil)
    tab = (variant.product.product_type == 'kit' ? 'knit-your-own': 'made-by-the-gang')
    pp = (variant.product.product_group.product_pages.where(target_id: t).first || variant.product.product_group.product_pages.first)
    permalink = (pp ? pp.permalink : 'not-found')
    product_page_path(id: permalink, tab: tab, variant_id: variant.id)
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
