# This migration comes from spree (originally 20131011154613)
class MoveTaxonsFromProductsToProductGroups < ActiveRecord::Migration
  def up
    rename_column :spree_products_taxons, :product_id, :product_group_id
    rename_table :spree_products_taxons, :spree_classifications
  end

  def down
    rename_table :spree_classifications, :spree_products_taxons
    rename_column :spree_products_taxons, :product_group_id, :product_id
  end
end
