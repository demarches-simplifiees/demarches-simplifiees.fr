# frozen_string_literal: true

require "administrate/base_dashboard"

class OutdatedProcedureDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    libelle: Field::String,
    created_at: Field::DateTime,
    dossiers_close_to_expiration: Field::Number
  }.freeze
  COLLECTION_ATTRIBUTES = [:id, :libelle, :created_at, :dossiers_close_to_expiration].freeze
  COLLECTION_FILTERS = {}.freeze
  SHOW_PAGE_ATTRIBUTES = {}
end
