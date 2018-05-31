class AddCadreJuridiqueToProcedure < ActiveRecord::Migration[5.2]
  def change
    add_column :procedures, :cadre_juridique, :string
  end
end
