# frozen_string_literal: true

class AddVersionToAttestationTemplates < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    safety_assured do
      add_column :attestation_templates, :version, :integer, default: 1, null: false
      add_index :attestation_templates, [:procedure_id, :version], unique: true, algorithm: :concurrently
      remove_index :attestation_templates, :procedure_id, unique: true, algorithm: :concurrently
    end
  end
end
