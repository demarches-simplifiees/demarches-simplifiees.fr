class CreateExerciceTable < ActiveRecord::Migration
  def change
    create_table :exercices do |t|
      t.string :ca
      t.datetime :dateFinExercice
      t.integer :date_fin_exercice_timestamp
    end

    add_reference :exercices, :etablissement, references: :etablissements
  end
end
