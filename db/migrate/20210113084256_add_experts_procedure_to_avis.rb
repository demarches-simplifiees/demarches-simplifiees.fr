# frozen_string_literal: true

class AddExpertsProcedureToAvis < ActiveRecord::Migration[6.0]
  def change
    add_reference :avis, :experts_procedure, foreign_key: true
  end
end
