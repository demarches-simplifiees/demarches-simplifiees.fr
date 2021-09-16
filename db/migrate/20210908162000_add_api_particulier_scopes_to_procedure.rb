class AddAPIParticulierScopesToProcedure < ActiveRecord::Migration[6.1]
  def change
    add_column :procedures, :api_particulier_scopes, :text, array: true, default: []
  end
end
