class CreateS3Synchronizations < ActiveRecord::Migration[6.0]
  def change
    create_table :s3_synchronizations do |t|
      t.string :target
      t.references :active_storage_blob
      t.boolean :checked

      t.timestamps

      t.index [:target, :active_storage_blob_id], unique: true
    end
  end
end
