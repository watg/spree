class AddBatchPrintingToSpreeOrders < ActiveRecord::Migration
  def change
    add_column :spree_orders, :batch_print_id, :string
    add_column :spree_orders, :batch_invoice_print_date, :date
    add_column :spree_orders, :batch_sticker_print_date, :date
  end
end
