require_relative '20200416123601_create_archives'

class CreateArchiveForGroupeInstructeur < ActiveRecord::Migration[6.0]
  def change
    revert CreateArchives

    create_table :archives do |t|
      t.string :status
      t.datetime :month
      t.string :content_type
      t.timestamps
    end

    create_table "archives_groupe_instructeurs", force: :cascade do |t|
      t.bigint "archive_id", null: false
      t.bigint "groupe_instructeur_id", null: false

      t.timestamps
    end
  end
end
