class AddEventEncryptionKeyToDossiers < ActiveRecord::Migration[6.1]
  def change
    add_column :dossiers, :event_encryption_key, :text
  end
end
