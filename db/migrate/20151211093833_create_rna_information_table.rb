class CreateRNAInformationTable < ActiveRecord::Migration
  def change
    create_table :rna_informations do |t|
      t.string :association_id
      t.string :titre
      t.text :objet
      t.date :date_creation
      t.date :date_declaration
      t.date :date_publication
    end

    add_reference :rna_informations, :entreprise, references: :entreprise
  end
end
