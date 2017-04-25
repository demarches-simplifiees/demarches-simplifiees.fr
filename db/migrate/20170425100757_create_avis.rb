class CreateAvis < ActiveRecord::Migration[5.0]
  def change
    create_table :avis do |t|
      t.string :email
      t.text :introduction
      t.text :answer
      t.references :gestionnaire
      t.references :dossier

      t.timestamps
    end
  end
end
