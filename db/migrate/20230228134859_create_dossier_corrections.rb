# frozen_string_literal: true

class CreateDossierCorrections < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    create_table :dossier_corrections do |t|
      # foreign keys are added in a later migration
      # see https://github.com/fatkodima/online_migrations#adding-multiple-foreign-keys
      t.references :dossier, null: false, foreign_key: false
      t.references :commentaire, foreign_key: false
      t.datetime :resolved_at, precision: 6

      t.timestamps
    end

    add_index :dossier_corrections, :resolved_at, where: "(resolved_at IS NULL OR resolved_at IS NOT NULL)", algorithm: :concurrently
  end
end
