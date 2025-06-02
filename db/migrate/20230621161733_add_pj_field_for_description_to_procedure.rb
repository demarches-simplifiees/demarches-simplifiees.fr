# frozen_string_literal: true

class AddPjFieldForDescriptionToProcedure < ActiveRecord::Migration[7.0]
  def change
    add_column :procedures, :description_pj, :string
  end
end
