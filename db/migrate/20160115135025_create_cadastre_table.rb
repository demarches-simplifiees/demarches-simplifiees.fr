class CreateCadastreTable < ActiveRecord::Migration[5.2]
  def change
    create_table :cadastres do |t|
      t.string :surface_intersection
      t.float :surface_parcelle
      t.string :numero
      t.integer :feuille
      t.string :section
      t.string :code_dep
      t.string :nom_com
      t.string :code_com
      t.string :code_arr
      t.text :geometry
    end

    add_reference :cadastres, :dossier, references: :dossiers
  end
end
