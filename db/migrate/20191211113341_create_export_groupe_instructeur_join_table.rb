# frozen_string_literal: true

class CreateExportGroupeInstructeurJoinTable < ActiveRecord::Migration[5.2]
  create_table "exports_groupe_instructeurs", force: :cascade do |t|
    t.bigint "export_id", null: false
    t.bigint "groupe_instructeur_id", null: false

    t.timestamps
  end
end
