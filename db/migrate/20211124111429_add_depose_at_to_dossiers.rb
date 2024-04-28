# frozen_string_literal: true

class AddDeposeAtToDossiers < ActiveRecord::Migration[6.1]
  def change
    add_column :dossiers, :depose_at, :datetime
  end
end
