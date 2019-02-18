class CreateTrustedDeviceTokens < ActiveRecord::Migration[5.2]
  def change
    create_table :trusted_device_tokens do |t|
      t.string :token, null: false
      t.references :gestionnaire, foreign_key: true

      t.timestamps
    end
    add_index :trusted_device_tokens, :token, unique: true
  end
end
