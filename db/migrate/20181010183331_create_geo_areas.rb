class CreateGeoAreas < ActiveRecord::Migration[5.2]
  def change
    create_table :geo_areas do |t|
      t.string :source, index: true

      t.jsonb :geometry
      t.jsonb :properties

      t.references :champ, foreign_key: true, index: true
    end

    add_column :types_de_champ, :options, :jsonb
  end
end
