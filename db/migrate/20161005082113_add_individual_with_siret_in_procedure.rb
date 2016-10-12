class AddIndividualWithSiretInProcedure < ActiveRecord::Migration
  def change
    add_column :procedures, :individual_with_siret, :boolean, default: false
  end
end
