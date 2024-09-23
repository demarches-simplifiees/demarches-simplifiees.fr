# frozen_string_literal: true

class RemoveHiddenAtColumnFromDossiers < ActiveRecord::Migration[7.0]
  def change
    safety_assured { remove_columns :dossiers, :hidden_at }
  end
end
