# frozen_string_literal: true

class AddEstimatedDossiersCountAndDossiersCountComputedAtToProcedures < ActiveRecord::Migration[6.1]
  def change
    add_column :procedures, :estimated_dossiers_count, :integer
    add_column :procedures, :dossiers_count_computed_at, :datetime
  end
end
