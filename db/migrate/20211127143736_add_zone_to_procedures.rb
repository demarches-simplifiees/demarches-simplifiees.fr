# frozen_string_literal: true

class AddZoneToProcedures < ActiveRecord::Migration[6.1]
  def change
    add_reference :procedures, :zone, null: true, foreign_key: true
  end
end
