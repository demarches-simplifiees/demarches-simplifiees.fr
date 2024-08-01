# frozen_string_literal: true

class AddUnpublishedAtToProcedures < ActiveRecord::Migration[5.2]
  def change
    add_column :procedures, :unpublished_at, :datetime
  end
end
