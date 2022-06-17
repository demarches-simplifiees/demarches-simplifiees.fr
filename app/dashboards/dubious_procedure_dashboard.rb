require "administrate/base_dashboard"

class DubiousProcedureDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    libelle: Field::String,
    dubious_champs: Field::String,
    aasm_state: Field::String
  }.freeze
  COLLECTION_ATTRIBUTES = [:id, :libelle, :dubious_champs, :aasm_state].freeze
  COLLECTION_FILTERS = {}.freeze
end
