# frozen_string_literal: true

class AddChorusColumnToProcedure < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      add_column :procedures, :chorus, :jsonb, default: {}, null: false
    end
  end
end
