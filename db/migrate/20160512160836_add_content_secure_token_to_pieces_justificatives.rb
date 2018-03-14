class AddContentSecureTokenToPiecesJustificatives < ActiveRecord::Migration[5.2]
  def change
    add_column :pieces_justificatives, :content_secure_token, :string
  end
end
