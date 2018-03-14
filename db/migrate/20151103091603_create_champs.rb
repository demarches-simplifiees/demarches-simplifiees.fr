class CreateChamps < ActiveRecord::Migration[5.2]
  def change
    create_table :champs do |t|
      t.string :value
    end
    add_reference :champs, :type_de_champs, references: :types_de_champs
    add_reference :champs, :dossier, references: :dossiers
  end
end
