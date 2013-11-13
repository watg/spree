module Spree
  class UpdateProductPageService < Mutations::Command
    required do
      model :product_page, class: 'Spree::ProductPage'
      duck  :details
      duck  :tabs
    end

    def execute
      ActiveRecord::Base.transaction do
        product_group.name        = details[:name]
        product_group.title       = details[:title]
        product_group.permalink   = details[:permalink]
        product_group.tags        = find_tags(details[:tags] || [])
        product_group.save!

        update_product_group_tabs
      end
    rescue Exception => e
      Rails.logger.error "[ProductPageUpdateService] #{e.message} -- #{e.backtrace}"
      add_error(:product_update, :exception, e.message)
    end

    private
    def update_product_group_tabs
      tabs.each do |tab_type, data|
        tab = product_group.tab(tab_type)
        update_tab_banner(tab, data)
        tab.position = data[:position]
        tab.background_color_code = data[:background_color_code]
        tab.save!
      end
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
