# frozen_string_literal: true

class AddUpdatedByToChamps < ActiveRecord::Migration[7.0]
  def change
    add_column :champs, :updated_by, :text
  end
end
