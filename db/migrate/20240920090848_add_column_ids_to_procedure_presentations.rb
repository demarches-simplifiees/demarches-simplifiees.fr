# frozen_string_literal: true

class AddColumnIdsToProcedurePresentations < ActiveRecord::Migration[7.0]
  def change
    add_column :procedure_presentations, :displayed_columns, :jsonb, array: true, default: [], null: false
    add_column :procedure_presentations, :tous_filters, :jsonb, array: true, default: [], null: false
    add_column :procedure_presentations, :suivis_filters, :jsonb, array: true, default: [], null: false
    add_column :procedure_presentations, :traites_filters, :jsonb, array: true, default: [], null: false
    add_column :procedure_presentations, :a_suivre_filters, :jsonb, array: true, default: [], null: false
    add_column :procedure_presentations, :archives_filters, :jsonb, array: true, default: [], null: false
    add_column :procedure_presentations, :expirant_filters, :jsonb, array: true, default: [], null: false
    add_column :procedure_presentations, :supprimes_filters, :jsonb, array: true, default: [], null: false
    add_column :procedure_presentations, :supprimes_recemment_filters, :jsonb, array: true, default: [], null: false
    add_column :procedure_presentations, :sorted_column, :jsonb
  end
end
