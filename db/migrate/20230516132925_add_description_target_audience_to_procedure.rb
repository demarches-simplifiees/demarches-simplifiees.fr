# frozen_string_literal: true

class AddDescriptionTargetAudienceToProcedure < ActiveRecord::Migration[7.0]
  def change
    add_column :procedures, :description_target_audience, :string
  end
end
