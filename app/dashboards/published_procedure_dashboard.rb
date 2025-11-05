# frozen_string_literal: true

require "administrate/base_dashboard"

class PublishedProcedureDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    libelle: Field::Text.with_options(truncate: 1000),
    description: Field::Text.with_options(truncate: 1000),
    service: Field::HasOne,
    published_at: Field::DateTime,
  }.freeze
  COLLECTION_ATTRIBUTES = [:id, :published_at, :libelle, :description, :service].freeze
  COLLECTION_FILTERS = {}.freeze
  SHOW_PAGE_ATTRIBUTES = {}
end
