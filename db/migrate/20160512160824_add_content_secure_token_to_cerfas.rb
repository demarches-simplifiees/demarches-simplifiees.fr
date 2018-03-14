class AddContentSecureTokenToCerfas < ActiveRecord::Migration[5.2]
  def change
    add_column :cerfas, :content_secure_token, :string
  end
end
