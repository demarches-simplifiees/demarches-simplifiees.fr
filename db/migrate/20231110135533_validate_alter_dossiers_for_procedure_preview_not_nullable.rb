# frozen_string_literal: true

class ValidateAlterDossiersForProcedurePreviewNotNullable < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      validate_check_constraint :dossiers, name: "dossiers_for_procedure_preview_null"
      change_column_null :dossiers, :for_procedure_preview, false, false
      remove_check_constraint :dossiers, name: "dossiers_for_procedure_preview_null"
    end
  end
end
