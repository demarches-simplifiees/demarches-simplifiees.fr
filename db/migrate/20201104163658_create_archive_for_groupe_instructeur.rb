# frozen_string_literal: true

class CreateArchiveForGroupeInstructeur < ActiveRecord::Migration[6.0]
  def change
    create_table :archives do |t|
      t.string :status, null: false
      t.date :month
      t.string :content_type, null: false
      t.timestamps
    end

    create_table "archives_groupe_instructeurs", force: :cascade do |t|
      t.belongs_to :archive, foreign_key: true, null: false
      t.belongs_to :groupe_instructeur, foreign_key: true, null: false

      t.timestamps
    end
  end
end
