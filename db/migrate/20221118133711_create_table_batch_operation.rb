class CreateTableBatchOperation < ActiveRecord::Migration[6.1]
  def change
    create_table :batch_operations do |t|
      t.bigint :instructeur_id, null: false
      t.string :operation, null: false
      t.jsonb :payload, default: {}, null: false
      t.bigint :failed_dossier_ids, array: true, default: [], null: false
      t.bigint :success_dossier_ids, array: true, default: [], null: false
      t.datetime :run_at
      t.datetime :finished_at
      t.timestamps
    end
  end
end
