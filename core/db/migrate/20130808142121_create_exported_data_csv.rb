class CreateExportedDataCsv < ActiveRecord::Migration
  def up
    create_table :spree_exported_data_csvs do |t|
      t.timestamps
      t.has_attached_file :csv_file
      t.string :type
      t.integer :job_id
    end
  end
  def down
    drop_table :spree_exported_data_csvs
  end
end
