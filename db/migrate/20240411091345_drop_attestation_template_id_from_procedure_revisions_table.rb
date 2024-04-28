# frozen_string_literal: true

class DropAttestationTemplateIdFromProcedureRevisionsTable < ActiveRecord::Migration[7.0]
  def up
    safety_assured do
      remove_column :procedure_revisions, :attestation_template_id
    end
  end
end
