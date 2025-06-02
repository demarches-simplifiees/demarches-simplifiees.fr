# frozen_string_literal: true

class AddAccuseLectureToProcedures < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      add_column :procedures, :accuse_lecture, :boolean, default: false, null: false
    end
  end
end
