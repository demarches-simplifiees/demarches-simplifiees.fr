class AddHasProcedureToPrefListDossier < ActiveRecord::Migration
  def change
    add_belongs_to :preference_list_dossiers, :procedure
  end
end
