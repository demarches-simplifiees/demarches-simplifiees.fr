class AddUseAdmiFacileToRefFormulaire < ActiveRecord::Migration
  def change
    add_column :ref_formulaires, :use_admi_facile, :boolean
  end
end
