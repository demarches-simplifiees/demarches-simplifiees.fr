class AddLogoSecureTokenColumnToAttestationTemplate < ActiveRecord::Migration[5.2]
  def change
    add_column :attestation_templates, :logo_secure_token, :string
  end
end
