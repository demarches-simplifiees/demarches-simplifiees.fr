class ChangeDatePrevisionnelDataType < ActiveRecord::Migration[5.2]
  def change
    remove_column :dossiers, :date_previsionnelle
    add_column :dossiers, :date_previsionnelle, :date
  end
end
