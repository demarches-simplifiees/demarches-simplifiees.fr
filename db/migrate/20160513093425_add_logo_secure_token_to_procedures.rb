class AddLogoSecureTokenToProcedures < ActiveRecord::Migration[5.2]
  def change
    add_column :procedures, :logo_secure_token, :string
  end
end
