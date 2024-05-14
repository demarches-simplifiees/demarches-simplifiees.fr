# frozen_string_literal: true

class AddPrefillFieldsToDossiers < ActiveRecord::Migration[6.1]
  def change
    add_column :dossiers, :prefill_token, :string
    add_column :dossiers, :prefilled, :boolean
  end
end
