class AddPayloadToDossierOperationLogs < ActiveRecord::Migration[5.2]
  def change
    add_column :dossier_operation_logs, :payload, :jsonb
  end
end
