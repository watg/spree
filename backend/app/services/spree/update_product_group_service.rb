module Spree
  class UpdateProductGroupService < Mutations::Command
    required do
      model :product_group, class: 'Spree::ProductGroup'
      duck  :details
      duck  :tabs
    end

    def execute
      ActiveRecord::Base.transaction do
        product_group.name        = details[:name]
        product_group.title       = details[:title]
        product_group.permalink   = details[:permalink]
        product_group.save!

        update_product_group_tabs
      end
    rescue Exception => e
      Rails.logger.error "[ProductGroupUpdateService] #{e.message} -- #{e.backtrace}"
      add_error(:product_update, :exception, e.message)
    end

    private
    def update_product_group_tabs
      tabs.each do |tab_type, data|
        tab = product_group.tab(tab_type)
        update_tab_banner(tab, data)
        make_tab_default(tab, details)
        tab.position    = data[:position]
        tab.taxons      = find_taxons(data[:taxon_ids])
        tab.description = data[:description]
        tab.save!
      end
    end

    def find_taxons(taxon_ids)
      ids = taxon_ids.split(",")
      Spree::Taxon.find(ids)
    end

    def update_tab_banner(tab, data)
      tab.banner = data[:banner] unless data[:banner].blank?
      tab
    end

    def make_tab_default(tab, details)
      tab.make_default(save: false) if tab.tab_type.to_s == details[:default_tab] 
      tab
    end
  end
end
