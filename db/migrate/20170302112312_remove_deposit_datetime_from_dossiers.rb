class RemoveDepositDatetimeFromDossiers < ActiveRecord::Migration[5.0]
  def change
    remove_column :dossiers, :deposit_datetime, :datetime
  end

  def up
    Dossier.where.not(deposit_datetime: nil).each do |dossier|
      dossier.update(initiated_at: dossier.deposit_datetime)
    end
  end

  def down
    Dossier.where.not(initiated_at: nil).each do |dossier|
      dossier.update(deposit_datetime: dossier.initiated_at)
    end
  end
end
