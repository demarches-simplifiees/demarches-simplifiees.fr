class AddNewUniqueIndexAttestationTemplates < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    remove_index :attestation_templates,
     name: "index_attestation_templates_on_procedure_version_state"

    add_index :attestation_templates,
      [:procedure_id, :version, :state, :kind],
      unique: true,
      name: "index_attestation_templates_on_procedure_version_state_kind",
      algorithm: :concurrently
  end
end
