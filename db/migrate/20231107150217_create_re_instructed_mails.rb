# frozen_string_literal: true

class CreateReInstructedMails < ActiveRecord::Migration[7.0]
  def change
    create_table :re_instructed_mails do |t|
      t.text :body
      t.string :subject
      t.integer :procedure_id, null: false

      t.timestamps
    end
    add_index :re_instructed_mails, :procedure_id
  end
end
