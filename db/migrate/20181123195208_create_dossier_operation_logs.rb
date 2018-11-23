class CreateDossierOperationLogs < ActiveRecord::Migration[5.2]
  def change
    create_table :dossier_operation_logs do |t|
      t.string :operation, null: false
      t.references :dossier, foreign_key: true, index: true
      t.references :gestionnaire, foreign_key: true, index: true

      t.timestamps
    end
  end
end
