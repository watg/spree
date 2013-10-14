module Spree
  class UpdateProductGroupService < Mutations::Command
    required do
      model :product_group, class: 'Spree::ProductGroup'
      duck  :details
    end

    def execute
      ActiveRecord::Base.transaction do
        product_group.name = details[:name]
        ids = details[:taxon_ids].split(",")
        taxons = Spree::Taxon.find(ids)
        product_group.taxons = taxons
        product_group.save!
      end
    rescue Exception => e
      Rails.logger.error "[ProductGroupUpdateService] #{e.message} -- #{e.backtrace}"
      add_error(:product_update, :exception, e.message)
    end
  end
end
