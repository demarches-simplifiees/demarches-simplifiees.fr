class AlterAttestationTemplateUnicityIndex < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_index :attestation_templates, [:procedure_id, :version, :state], name: "index_attestation_templates_on_procedure_version_state", unique: true, algorithm: :concurrently
    remove_index :attestation_templates, [:procedure_id, :version], unique: true, algorithm: :concurrently
  end
end
