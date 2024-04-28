# frozen_string_literal: true

require "administrate/base_dashboard"

class DubiousProcedureDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    libelle: Field::String,
    dubious_champs: Field::String,
    aasm_state: Field::String,
    hidden_at_as_template: Field::DateTime.with_options(format: "%d/%m/%Y")
  }.freeze
  COLLECTION_ATTRIBUTES = [:id, :libelle, :dubious_champs, :aasm_state, :hidden_at_as_template].freeze
  COLLECTION_FILTERS = {}.freeze
end
