# frozen_string_literal: true

class AddReInstructedAtToDossiers < ActiveRecord::Migration[7.0]
  def change
    add_column :dossiers, :re_instructed_at, :datetime
  end
end
