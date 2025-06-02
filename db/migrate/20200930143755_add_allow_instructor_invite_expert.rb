# frozen_string_literal: true

class AddAllowInstructorInviteExpert < ActiveRecord::Migration[6.0]
  def change
    add_column :procedures, :allow_expert_review, :boolean, default: true, null: false
  end
end
