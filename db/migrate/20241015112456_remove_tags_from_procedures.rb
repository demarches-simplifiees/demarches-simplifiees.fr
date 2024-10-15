# frozen_string_literal: true

class RemoveTagsFromProcedures < ActiveRecord::Migration[7.0]
  def change
    remove_index :procedures, name: "index_procedures_on_tags"

    safety_assured do
      remove_column :procedures, :tags, :text, array: true, default: []
    end
  end
end
