class CreateVirusScans < ActiveRecord::Migration[5.2]
  def change
    create_table :virus_scans do |t|
      t.datetime :scanned_at
      t.string :status
      t.references :champ, index: true
      t.string :blob_key

      t.timestamps
    end
  end
end
