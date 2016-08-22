class AddDepositAttrInDossierTable < ActiveRecord::Migration
  def change
    add_column :dossiers, :deposit_datetime, :datetime
  end
end
