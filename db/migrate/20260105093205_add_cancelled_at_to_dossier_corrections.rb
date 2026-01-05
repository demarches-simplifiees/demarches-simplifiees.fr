# frozen_string_literal: true

class AddCancelledAtToDossierCorrections < ActiveRecord::Migration[7.2]
  def change
    add_column :dossier_corrections, :cancelled_at, :datetime
  end
end
