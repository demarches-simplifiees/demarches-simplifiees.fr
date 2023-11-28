class AddFromSupportToDossierTransfers < ActiveRecord::Migration[7.0]
  def change
    add_column :dossier_transfers, :from_support, :boolean, default: false, null: false
  end
end
