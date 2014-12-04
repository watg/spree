# -*- coding: utf-8 -*-
module ApplicationHelper
  include Spree::ProductsHelper
  include Spree::BaseHelper
  include Spree::CdnHelper
  include Spree::OrdersHelper

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
    if Flip.on? :suites_feature
      suite = Spree::Suite.unscoped.find_by(id: line_item.suite_id)
      return '#' unless suite

      permalink = suite.permalink

      tab = Spree::SuiteTab.unscoped.find_by(id: line_item.suite_tab_id)
      tab_type = tab.try(:tab_type)

      if !tab_type || variant.assembly_definition.present?
        spree.suite_path(id: permalink, tab: tab_type)
      else
        spree.suite_path(id: permalink, tab: tab_type, variant_id: variant.number)
      end

    else

      product_page = line_item.product_page || Spree::ProductPage.unscoped.find_by(id: line_item.product_page_id)
      return '#' unless product_page

      permalink = product_page.permalink

      tab = line_item.product_page_tab || Spree::ProductPageTab.unscoped.find_by(id: line_item.product_page_tab_id)

      safe_tab = ( tab ? tab.url_safe_tab_type : '')

      if variant.assembly_definition.present?
        spree.product_page_path(id: permalink, tab: safe_tab)
      else
        spree.product_page_path(id: permalink, tab: safe_tab, variant_id: variant.number)
      end

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
