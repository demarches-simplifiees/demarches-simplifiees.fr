require "administrate/base_dashboard"

class ProcedureDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    types_de_piece_justificative: TypesDePieceJustificativeCollectionField,
    types_de_champ: TypesDeChampCollectionField,
    dossiers: Field::HasMany,
    procedure_path: Field::HasOne,
    administrateur: Field::BelongsTo,
    id: Field::Number,
    libelle: Field::String,
    description: Field::String,
    organisation: Field::String,
    direction: Field::String,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
    for_individual: Field::Boolean,
    individual_with_siret: Field::Boolean,
    auto_archive_on: Field::DateTime,
    published_at: Field::DateTime,
    hidden_at: Field::DateTime,
    archived_at: Field::DateTime,
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = [
    :id,
    :created_at,
    :libelle,
    :organisation,
    :dossiers,
    :published_at,
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = [
    :id,
    :libelle,
    :description,
    :organisation,
    :direction,
    :created_at,
    :updated_at,
    :published_at,
    :hidden_at,
    :archived_at,
    :types_de_champ,
    :types_de_piece_justificative,
    :for_individual,
    :individual_with_siret,
    :auto_archive_on,
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = [].freeze

  # Overwrite this method to customize how procedures are displayed
  # across all pages of the admin dashboard.
  #
  # def display_resource(procedure)
  #   "Procedure ##{procedure.id}"
  # end
end
