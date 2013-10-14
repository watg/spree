class DropDisplayableVariants < ActiveRecord::Migration
  def up
    drop_table :spree_displayable_variants
  end

  def down
    create_table :spree_displayable_variants do |t|
      t.integer :product_id
      t.integer :taxon_id
      t.integer :variant_id
      t.integer :position
      t.timestamps
    end
  end
end
