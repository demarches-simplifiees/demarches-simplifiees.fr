# frozen_string_literal: true

class CreateGestionnaires < ActiveRecord::Migration[7.0]
  def change
    create_table "gestionnaires" do |t|
      t.bigint :user_id, null: false
      t.index [:user_id], name: :index_gestionnaires_on_user_id
      t.timestamps
    end
  end
end
