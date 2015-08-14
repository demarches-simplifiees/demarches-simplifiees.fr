class RenameRefDemarcheIntoDemarcheId < ActiveRecord::Migration
  def change
    rename_column :formulaires, :ref_demarche, :demarche_id
  end
end
