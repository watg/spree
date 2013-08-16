class AddColumnVisibleToSpreeProductOptionTypes < ActiveRecord::Migration
  def change
    add_column :spree_product_option_types, :visible, :boolean, :default => false
  end
end
