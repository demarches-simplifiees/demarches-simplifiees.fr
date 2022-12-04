class CreateDossierSnapshots < ActiveRecord::Migration[6.1]
  def change
    create_table :dossier_snapshots, id: :uuid do |t|
      t.references :dossier, null: false, foreign_key: true
      t.jsonb :data
      t.timestamps
    end
  end
end
