# frozen_string_literal: true

class RemoveAdministrationIdFromDossierOperationLogs < ActiveRecord::Migration[5.2]
  def change
    remove_column :dossier_operation_logs, :administration_id, :bigint
  end
end
