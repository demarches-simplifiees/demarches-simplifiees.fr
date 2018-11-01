class CreateAccounts < ActiveRecord::Migration[5.2]
  def change
    create_table :accounts do |t|
      t.string :email, index: true

      t.references :usager
      t.references :instructeur
      t.references :administrateur, foreign_key: true

      t.timestamps
    end
  end
end
