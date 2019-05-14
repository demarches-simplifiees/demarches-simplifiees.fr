class AddDigestAndTimestampsToDossierOperationLogs < ActiveRecord::Migration[5.2]
  def change
    add_column :dossier_operation_logs, :keep_until, :datetime
    add_column :dossier_operation_logs, :executed_at, :datetime
    add_column :dossier_operation_logs, :digest, :text
    add_index :dossier_operation_logs, :keep_until
  end
end
