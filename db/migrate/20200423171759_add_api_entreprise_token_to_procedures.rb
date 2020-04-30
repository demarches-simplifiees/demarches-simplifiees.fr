class AddAPIEntrepriseTokenToProcedures < ActiveRecord::Migration[5.2]
  def change
    add_column :procedures, :api_entreprise_token, :string
  end
end
