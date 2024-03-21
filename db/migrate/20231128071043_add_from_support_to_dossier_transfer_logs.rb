class AddFromSupportToDossierTransferLogs < ActiveRecord::Migration[7.0]
  def change
    add_column :dossier_transfer_logs, :from_support, :boolean, default: false, null: false
  end
end
