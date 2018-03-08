class RenameRefDemarcheIntoDemarcheId < ActiveRecord::Migration[5.2]
  def change
    rename_column :formulaires, :ref_demarche, :demarche_id
  end
end
