# frozen_string_literal: true

class AlterDossiersForProcedurePreviewNotNullable < ActiveRecord::Migration[7.0]
  def change
    add_check_constraint :dossiers, "for_procedure_preview IS NOT NULL", name: "dossiers_for_procedure_preview_null", validate: false
  end
end
