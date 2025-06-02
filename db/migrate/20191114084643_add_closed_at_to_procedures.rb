# frozen_string_literal: true

class AddClosedAtToProcedures < ActiveRecord::Migration[5.2]
  def change
    add_column :procedures, :closed_at, :datetime
  end
end
