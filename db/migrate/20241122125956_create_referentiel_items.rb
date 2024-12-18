# frozen_string_literal: true

class CreateReferentielItems < ActiveRecord::Migration[7.0]
  def change
    create_table :referentiel_items do |t|
      t.references :referentiel, null: false, foreign_key: true
      t.jsonb :option, null: false, default: {}
      t.jsonb :data, default: {}
      t.timestamps
    end
  end
end
