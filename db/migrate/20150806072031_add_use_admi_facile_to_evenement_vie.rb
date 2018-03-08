class AddUseAdmiFacileToEvenementVie < ActiveRecord::Migration[5.2]
  def change
    add_column :evenement_vies, :use_admi_facile, :boolean
  end
end
