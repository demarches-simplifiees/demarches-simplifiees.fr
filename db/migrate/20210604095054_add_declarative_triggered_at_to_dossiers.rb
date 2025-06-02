# frozen_string_literal: true

class AddDeclarativeTriggeredAtToDossiers < ActiveRecord::Migration[6.1]
  def change
    add_column :dossiers, :declarative_triggered_at, :datetime
  end
end
