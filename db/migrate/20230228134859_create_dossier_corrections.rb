class CreateDossierCorrections < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    create_table :dossier_corrections do |t|
      t.references :dossier, null: false, foreign_key: true
      t.references :commentaire, foreign_key: true
      t.datetime :resolved_at, precision: 6

      t.timestamps
    end

    add_index :dossier_corrections, :resolved_at, where: "(resolved_at IS NULL OR resolved_at IS NOT NULL)", algorithm: :concurrently
  end
end
