class AddAutomaticOperationColumnToDossierOperationLog < ActiveRecord::Migration[5.2]
  def change
    add_column :dossier_operation_logs, :automatic_operation, :bool, default: false, null: false
  end
end
