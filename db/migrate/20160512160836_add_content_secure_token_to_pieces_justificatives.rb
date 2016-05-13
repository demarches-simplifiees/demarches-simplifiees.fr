class AddContentSecureTokenToPiecesJustificatives < ActiveRecord::Migration
  def change
    add_column :pieces_justificatives, :content_secure_token, :string
  end
end
