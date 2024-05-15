require "administrate/base_dashboard"

class ProcedureDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    published_types_de_champ_public: TypesDeChampCollectionField,
    published_types_de_champ_private: TypesDeChampCollectionField,
    path: ProcedureLinkField,
    aasm_state: ProcedureStateField,
    dossiers: Field::HasMany,
    administrateurs: Field::HasMany,
    instructeurs: Field::HasMany,
    groupe_instructeurs: Field::HasMany,
    routing_champs: Field::Text,
    id: Field::Number.with_options(searchable: true),
    libelle: Field::String,
    description: Field::String,
    zones: Field::HasMany,
    lien_site_web: Field::String, # TODO: use Field::Url when administrate-v0.12 will be released
    organisation: Field::String,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
    for_individual: Field::Boolean,
    auto_archive_on: Field::DateTime,
    published_at: Field::DateTime,
    unpublished_at: Field::DateTime,
    hidden_at: Field::DateTime,
    closed_at: Field::DateTime,
    whitelisted_at: Field::DateTime,
    hidden_at_as_template: Field::DateTime,
    service: Field::BelongsTo,
    passer_en_construction_email_template: MailTemplateField,
    passer_en_instruction_email_template: MailTemplateField,
    accepter_email_template: MailTemplateField,
    refuser_email_template: MailTemplateField,
    classer_sans_suite_email_template: MailTemplateField,
    repasser_en_instruction_email_template: MailTemplateField,
    attestation_template: AttestationTemplateField,
    procedure_expires_when_termine_enabled: Field::Boolean,
    duree_conservation_dossiers_dans_ds: Field::Number,
    max_duree_conservation_dossiers_dans_ds: Field::Number,
    estimated_duration_visible: Field::Boolean,
    piece_justificative_multiple: Field::Boolean,
    for_tiers_enabled: Field::Boolean,
    replaced_by_procedure_id: Field::String,
    tags: Field::Text,
    template: Field::Boolean
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
    :zones,
    :service,
    :dossiers,
    :published_at,
    :aasm_state
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = [
    :id,
    :path,
    :aasm_state,
    :administrateurs,
    :instructeurs,
    :groupe_instructeurs,
    :routing_champs,
    :libelle,
    :description,
    :tags,
    :template,
    :lien_site_web,
    :organisation,
    :zones,
    :service,
    :created_at,
    :updated_at,
    :published_at,
    :whitelisted_at,
    :hidden_at,
    :hidden_at_as_template,
    :closed_at,
    :unpublished_at,
    :published_types_de_champ_public,
    :published_types_de_champ_private,
    :for_individual,
    :auto_archive_on,
    :passer_en_construction_email_template,
    :passer_en_instruction_email_template,
    :accepter_email_template,
    :refuser_email_template,
    :classer_sans_suite_email_template,
    :repasser_en_instruction_email_template,
    :attestation_template,
    :procedure_expires_when_termine_enabled,
    :duree_conservation_dossiers_dans_ds,
    :max_duree_conservation_dossiers_dans_ds,
    :estimated_duration_visible,
    :piece_justificative_multiple,
    :for_tiers_enabled,
    :replaced_by_procedure_id
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = [
    :procedure_expires_when_termine_enabled,
    :duree_conservation_dossiers_dans_ds,
    :max_duree_conservation_dossiers_dans_ds,
    :estimated_duration_visible,
    :piece_justificative_multiple,
    :for_tiers_enabled,
    :replaced_by_procedure_id
  ].freeze

  # Overwrite this method to customize how procedures are displayed
  # across all pages of the admin dashboard.
  #
  def display_resource(procedure)
    "#{procedure.libelle} ##{procedure.id}"
  end
end
