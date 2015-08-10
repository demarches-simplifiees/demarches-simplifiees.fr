class AddUseAdmiFacileToEvenementVie < ActiveRecord::Migration
  def change
    add_column :evenement_vies, :use_admi_facile, :boolean
  end
end
