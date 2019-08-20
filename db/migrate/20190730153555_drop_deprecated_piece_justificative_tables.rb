class DropDeprecatedPieceJustificativeTables < ActiveRecord::Migration[5.2]
  def change
    assert_empty_table!(:types_de_piece_justificative)
    assert_empty_table!(:pieces_justificatives)

    drop_table :types_de_piece_justificative do |t|
      t.string "libelle"
      t.string "description"
      t.boolean "api_entreprise", default: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.integer "procedure_id"
      t.integer "order_place"
      t.string "lien_demarche"
      t.boolean "mandatory", default: false
      t.index ["procedure_id"], name: "index_types_de_piece_justificative_on_procedure_id"
    end

    drop_table :pieces_justificatives do |t|
      t.string "content"
      t.integer "dossier_id"
      t.integer "type_de_piece_justificative_id"
      t.datetime "created_at"
      t.integer "user_id"
      t.string "original_filename"
      t.string "content_secure_token"
      t.datetime "updated_at"
      t.index ["dossier_id"], name: "index_pieces_justificatives_on_dossier_id"
      t.index ["type_de_piece_justificative_id"], name: "index_pieces_justificatives_on_type_de_piece_justificative_id"
    end
  end

  def assert_empty_table!(table)
    results = ActiveRecord::Base.connection.exec_query("SELECT COUNT(*) FROM #{table}")
    records_count = results.first['count']
    if records_count > 0
      raise "Abord dropping `#{table}` table: it still contains #{records_count} records."
    end
  end
end
