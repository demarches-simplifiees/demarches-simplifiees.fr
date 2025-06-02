# frozen_string_literal: true

class AddClosingReasonAndClosingDetails < ActiveRecord::Migration[7.0]
  def change
    add_column :procedures, :closing_reason, :string
    add_column :procedures, :closing_details, :string
  end
end
