class AddHasProcedureToPrefListDossier < ActiveRecord::Migration[5.2]
  def change
    add_belongs_to :preference_list_dossiers, :procedure
  end
end
