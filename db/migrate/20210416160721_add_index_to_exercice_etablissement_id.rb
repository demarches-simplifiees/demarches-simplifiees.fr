# frozen_string_literal: true

class AddIndexToExerciceEtablissementId < ActiveRecord::Migration[6.1]
  def change
    add_index :exercices, :etablissement_id
  end
end
