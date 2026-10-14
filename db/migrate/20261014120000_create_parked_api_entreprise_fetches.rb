# frozen_string_literal: true

class CreateParkedAPIEntrepriseFetches < ActiveRecord::Migration[8.1]
  def change
    create_table :parked_api_entreprise_fetches do |t|
      t.references :etablissement, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.string :job, null: false
      t.bigint :procedure_id, null: false
      t.jsonb :arguments, null: false
      t.integer :code
      t.integer :attempts, null: false, default: 1
      t.datetime :enqueued_at
      t.timestamps
    end

    add_index :parked_api_entreprise_fetches, [:etablissement_id, :job], unique: true
    add_index :parked_api_entreprise_fetches, [:job, :created_at]
  end
end
