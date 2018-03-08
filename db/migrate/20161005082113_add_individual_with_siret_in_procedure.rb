class AddIndividualWithSiretInProcedure < ActiveRecord::Migration[5.2]
  def change
    add_column :procedures, :individual_with_siret, :boolean, default: false
  end
end
