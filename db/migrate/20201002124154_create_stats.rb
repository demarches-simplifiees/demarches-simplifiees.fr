# frozen_string_literal: true

class CreateStats < ActiveRecord::Migration[6.0]
  def change
    create_table :stats do |t|
      t.bigint :dossiers_not_brouillon, default: 0
      t.bigint :dossiers_brouillon, default: 0
      t.bigint :dossiers_en_construction, default: 0
      t.bigint :dossiers_en_instruction, default: 0
      t.bigint :dossiers_termines, default: 0
      t.bigint :dossiers_depose_avant_30_jours, default: 0
      t.bigint :dossiers_deposes_entre_60_et_30_jours, default: 0
      t.bigint :administrations_partenaires, default: 0

      t.jsonb :dossiers_cumulative, null: false, default: '{}'
      t.jsonb :dossiers_in_the_last_4_months, null: false, default: '{}'

      t.timestamps
    end
  end
end
