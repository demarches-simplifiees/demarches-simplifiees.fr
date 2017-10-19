class AddSignatureSecureTokenColumnToAttestationTemplate < ActiveRecord::Migration[5.0]
  def change
    add_column :attestation_templates, :signature_secure_token, :string
  end
end
