# frozen_string_literal: true

class AddHiddenByReasonToDossiers < ActiveRecord::Migration[6.1]
  def change
    add_column :dossiers, :hidden_by_reason, :string
  end
end
