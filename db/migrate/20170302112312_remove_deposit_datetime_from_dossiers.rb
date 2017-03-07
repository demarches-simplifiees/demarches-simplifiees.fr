class RemoveDepositDatetimeFromDossiers < ActiveRecord::Migration[5.0]
  def change
    Dossier.where.not(deposit_datetime: nil).each do |dossier|
      dossier.update(initiated_at: dossier.deposit_datetime)
    end
    remove_column :dossiers, :deposit_datetime, :datetime
  end
end
