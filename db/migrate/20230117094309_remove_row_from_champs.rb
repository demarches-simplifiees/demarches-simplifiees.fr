# frozen_string_literal: true

class RemoveRowFromChamps < ActiveRecord::Migration[6.1]
  def change
    safety_assured { remove_columns :champs, :row }
  end
end
