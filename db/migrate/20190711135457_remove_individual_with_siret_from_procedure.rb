class RemoveIndividualWithSiretFromProcedure < ActiveRecord::Migration[5.2]
  def change
    remove_column :procedures, :individual_with_siret, :boolean, default: false
  end
end
