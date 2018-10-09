class CreateParcelleAgricoles < ActiveRecord::Migration[5.2]
  def change
    create_table :parcelle_agricoles do |t|
      t.text :geometry
    end

    add_column :module_api_cartos, :parcelles_agricoles, :boolean
    add_reference :parcelle_agricoles, :dossier, references: :dossiers
  end
end
