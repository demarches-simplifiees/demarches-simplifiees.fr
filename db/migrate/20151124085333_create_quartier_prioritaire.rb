class CreateQuartierPrioritaire < ActiveRecord::Migration[5.2]
  def change
    create_table :quartier_prioritaires do |t|
      t.string :code
      t.string :nom
      t.string :commune
      t.text :geometry
    end

    add_reference :quartier_prioritaires, :dossier, references: :dossiers
  end
end
