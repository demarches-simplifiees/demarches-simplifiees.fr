class AddContentSecureTokenToCerfas < ActiveRecord::Migration
  def change
    add_column :cerfas, :content_secure_token, :string
  end
end
