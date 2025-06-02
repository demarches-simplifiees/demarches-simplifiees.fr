# frozen_string_literal: true

class AddNotNullConstraintsToAdministrateursInstructeur < ActiveRecord::Migration[6.1]
  def change
    # We ignore strong_migrations safety warnings, because those tables are relatively small, and the null check
    # will be very fast.
    safety_assured do
      change_column_null :administrateurs_instructeurs, :administrateur_id, false
      change_column_null :administrateurs_instructeurs, :instructeur_id, false
    end
  end
end
