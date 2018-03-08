class AddContentSecureTokenColumnToAttestation < ActiveRecord::Migration[5.2]
  def change
    add_column :attestations, :content_secure_token, :string
  end
end
