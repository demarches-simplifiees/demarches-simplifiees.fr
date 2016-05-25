class AddLogoSecureTokenToProcedures < ActiveRecord::Migration
  def change
    add_column :procedures, :logo_secure_token, :string
  end
end
