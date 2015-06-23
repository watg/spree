# -*- coding: utf-8 -*-
module ApplicationHelper
  include Spree::ProductsHelper
  include Spree::BaseHelper
  include Spree::CdnHelper
  include Spree::OrdersHelper
  include Spree::IframeFormHelper

  def present(object, options, klass = nil)
    klass ||= "#{object.class}Presenter".constantize
    presenter = klass.new(object, self, options)
    yield presenter if block_given?
    presenter
  end

  def tracker_id
    @tracker_id ||= (YAML.load_file(File.join(Rails.root, 'config/ga.yaml'))[Rails.env])['tracker_id']
  end

  def production_or_staging?
    Rails.env.production? or Rails.env.staging?
  end

  def path_to_variant(line_item, variant)
    suite = Spree::Suite.unscoped.find_by(id: line_item.suite_id)
    return '#' unless suite

    permalink = suite.permalink

    tab = Spree::SuiteTab.unscoped.find_by(id: line_item.suite_tab_id)
    tab_type = tab.try(:tab_type)

    if !tab_type || variant.is_master?
      spree.suite_path(id: permalink, tab: tab_type)
    else
      spree.suite_path(id: permalink, tab: tab_type, variant_id: variant.number)
    end
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
