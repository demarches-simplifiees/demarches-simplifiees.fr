# frozen_string_literal: true

class AddAdministrateurIdToArchives < ActiveRecord::Migration[7.0]
  def change
    add_column :archives, :user_profile_id, :bigint
    add_column :archives, :user_profile_type, :string
  end
end
