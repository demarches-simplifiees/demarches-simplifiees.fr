class AddDepositAttrInDossierTable < ActiveRecord::Migration[5.2]
  def change
    add_column :dossiers, :deposit_datetime, :datetime
  end
end
