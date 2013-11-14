module Spree
  class UpdateProductPageService < Mutations::Command
    required do
      model :product_page, class: 'Spree::ProductPage'
      duck  :details
      duck  :tabs
    end

    def execute
      ActiveRecord::Base.transaction do
        product_page.name               = details[:name]
        product_page.title              = details[:title]
        product_page.permalink          = details[:permalink]
        product_page.product_group_ids  = split_params(details[:product_group_ids])
        product_page.tags               = find_tags(details[:tags] || [])
        product_page.save!

        update_product_page_tabs
      end
    rescue Exception => e
      Rails.logger.error "[ProductPageUpdateService] #{e.message} -- #{e.backtrace}"
      add_error(:product_update, :exception, e.message)
    end

    private
    def update_product_page_tabs
      tabs.each do |tab_type, data|
        tab = product_page.tab(tab_type)
        update_tab_banner(tab, data)
        tab.position = data[:position]
        tab.background_color_code = data[:background_color_code]
        tab.save!
      end
    end

    def split_params(input=nil)
      input.blank? ? [] : input.split(',').map(&:to_i)
    end  

    def update_tab_banner(tab, data)
      tab.banner = data[:banner] unless data[:banner].blank?
      tab
    end

    def find_tags(tag_ids)
      ids = tag_ids.map(&:to_i).select {|e| e > 0 }
      Spree::Tag.find(ids)
    end
  end
end
