# frozen_string_literal: true

class CreateMergeLogs < ActiveRecord::Migration[6.1]
  def change
    create_table :merge_logs do |t|
      t.bigint :from_user_id, null: false
      t.string :from_user_email, null: false
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
