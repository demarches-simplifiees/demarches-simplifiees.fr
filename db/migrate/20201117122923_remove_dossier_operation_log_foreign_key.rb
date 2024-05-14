# frozen_string_literal: true

class RemoveDossierOperationLogForeignKey < ActiveRecord::Migration[6.0]
  def change
    remove_foreign_key :dossier_operation_logs, :dossiers
  end
end
