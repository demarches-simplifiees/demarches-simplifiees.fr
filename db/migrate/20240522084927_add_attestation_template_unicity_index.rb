# frozen_string_literal: true

class AddAttestationTemplateUnicityIndex < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    # this index was not created on production
    if index_exists?(:attestation_templates, [:procedure_id, :version])
      remove_index :attestation_templates, [:procedure_id, :version], unique: true, algorithm: :concurrently
    end

    add_index :attestation_templates, [:procedure_id, :version, :state], name: "index_attestation_templates_on_procedure_version_state", unique: true, algorithm: :concurrently
  end
end
