# frozen_string_literal: true

class AddFiltersExpandedToProcedurePresentation < ActiveRecord::Migration[7.1]
  def change
    add_column :procedure_presentations, :filters_expanded, :boolean, default: true, null: false
  end
end
