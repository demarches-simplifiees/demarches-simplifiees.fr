class CreateDeletedDossiers < ActiveRecord::Migration[5.2]
  def change
    create_table :deleted_dossiers do |t|
      t.references :procedure
      t.bigint :dossier_id
      t.datetime :deleted_at
      t.string :state

      t.timestamps
    end
  end
end
