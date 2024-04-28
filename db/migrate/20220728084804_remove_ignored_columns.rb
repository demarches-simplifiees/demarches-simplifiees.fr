# frozen_string_literal: true

class RemoveIgnoredColumns < ActiveRecord::Migration[6.1]
  def change
    safety_assured do
      remove_column :commentaires, :user_id
      remove_column :dossiers, :en_construction_conservation_extension
    end
  end
end
