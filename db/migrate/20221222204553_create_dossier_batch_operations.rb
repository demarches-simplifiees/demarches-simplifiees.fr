# frozen_string_literal: true

class CreateDossierBatchOperations < ActiveRecord::Migration[6.1]
  def change
    create_table :dossier_batch_operations do |t|
      t.references :dossier, null: false, foreign_key: true
      t.references :batch_operation, null: false, foreign_key: true
      t.string :state, null: false, default: DossierBatchOperation.states.fetch(:pending)
      t.timestamps
    end
  end
end
