class CreateAttestations < ActiveRecord::Migration[5.2]
  def change
    create_table :attestations do |t|
      t.string :pdf
      t.string :title
      t.references :dossier, foreign_key: true, null: false

      t.timestamps
    end
  end
end
