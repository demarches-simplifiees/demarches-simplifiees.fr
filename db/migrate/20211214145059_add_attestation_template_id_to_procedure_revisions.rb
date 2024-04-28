# frozen_string_literal: true

class AddAttestationTemplateIdToProcedureRevisions < ActiveRecord::Migration[6.1]
  def change
    add_reference :procedure_revisions, :attestation_template, foreign_key: { to_table: :attestation_templates }, null: true, index: true
  end
end
