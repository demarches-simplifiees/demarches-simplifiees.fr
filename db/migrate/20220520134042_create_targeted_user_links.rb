# frozen_string_literal: true

class CreateTargetedUserLinks < ActiveRecord::Migration[6.1]
  def change
    # avoid target links with pk sequence
    create_table :targeted_user_links, id: :uuid do |t|
      t.string :target_context, null: false
      t.bigint :target_model_id, null: false
      t.string :target_model_type, null: false
      t.references :user, foreign_key: true, null: false

      t.timestamps
    end
  end
end
