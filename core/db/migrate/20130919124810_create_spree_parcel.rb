class CreateSpreeParcel < ActiveRecord::Migration
  def change
    create_table :spree_parcels do |t|
      t.integer  :box_id
      t.integer  :order_id
      t.integer  :value
      t.string   :currency
      t.string   :tracking_code
      t.string   :tracking_url
      t.timestamps
    end
  end
end
