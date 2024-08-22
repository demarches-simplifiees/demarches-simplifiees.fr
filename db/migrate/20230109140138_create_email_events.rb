# frozen_string_literal: true

class CreateEmailEvents < ActiveRecord::Migration[6.1]
  def change
    create_table :email_events do |t|
      t.string :to, null: false
      t.string :method, null: false
      t.string :status, null: false
      t.string :subject, null: false
      t.datetime :processed_at

      t.timestamps
    end
  end
end
