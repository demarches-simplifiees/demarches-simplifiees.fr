class CreateChampRevisions < ActiveRecord::Migration[7.0]
  def change
    create_table :champ_revisions do |t|
      t.references :champ, null: false, foreign_key: true, index: true
      t.references :instructeur, null: false, index: true
      t.jsonb :data
      t.references :etablissement
      t.string :external_id
      t.string :fetch_external_data_exceptions, array: true
      t.string :value
      t.jsonb :value_json

      t.timestamps
    end
  end
end
