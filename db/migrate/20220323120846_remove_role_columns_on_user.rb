# frozen_string_literal: true

class RemoveRoleColumnsOnUser < ActiveRecord::Migration[6.1]
  def change
    # (The safety_assured block validates that the columns to remove are ignored in the model, which is the case.)
    safety_assured do
      remove_column :users, :administrateur_id
      remove_column :users, :instructeur_id
      remove_column :users, :expert_id
    end
  end
end
