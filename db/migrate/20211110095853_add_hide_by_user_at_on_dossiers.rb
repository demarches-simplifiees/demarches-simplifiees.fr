# frozen_string_literal: true

class AddHideByUserAtOnDossiers < ActiveRecord::Migration[6.1]
  def change
    add_column :dossiers, :hidden_by_user_at, :datetime
  end
end
