class AddUseAdmiFacileToRefFormulaire < ActiveRecord::Migration[5.2]
  def change
    add_column :ref_formulaires, :use_admi_facile, :boolean
  end
end
