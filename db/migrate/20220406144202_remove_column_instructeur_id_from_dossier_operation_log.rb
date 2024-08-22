# frozen_string_literal: true

class RemoveColumnInstructeurIdFromDossierOperationLog < ActiveRecord::Migration[6.1]
  def change
    safety_assured { remove_column :dossier_operation_logs, :instructeur_id }
  end
end
