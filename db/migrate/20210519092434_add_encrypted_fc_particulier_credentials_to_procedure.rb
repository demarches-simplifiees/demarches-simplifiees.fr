class AddEncryptedFCParticulierCredentialsToProcedure < ActiveRecord::Migration[6.1]
  def change
    add_column :procedures, :encrypted_fc_particulier_id, :string
    add_column :procedures, :encrypted_fc_particulier_secret, :string
  end
end
