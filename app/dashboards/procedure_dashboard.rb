require "administrate/base_dashboard"

class ProcedureDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    published_types_de_champ: TypesDeChampCollectionField,
    published_types_de_champ_private: TypesDeChampCollectionField,
    path: ProcedureLinkField,
    dossiers: Field::HasMany,
    administrateurs: Field::HasMany,
    id: Field::Number.with_options(searchable: true),
    libelle: Field::String,
    description: Field::String,
    zone: Field::BelongsTo,
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
    service: Field::BelongsTo,
    initiated_mail_template: MailTemplateField,
    received_mail_template: MailTemplateField,
    closed_mail_template: MailTemplateField,
    refused_mail_template: MailTemplateField,
    without_continuation_mail_template: MailTemplateField,
    attestation_template: AttestationTemplateField,
    procedure_expires_when_termine_enabled: Field::Boolean,
    duree_conservation_dossiers_dans_ds: Field::Number,
    max_duree_conservation_dossiers_dans_ds: Field::Number
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
    :zone,
    :service,
    :dossiers,
    :published_at,
    :unpublished_at
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = [
    :id,
    :path,
    :administrateurs,
    :libelle,
    :description,
    :lien_site_web,
    :organisation,
    :zone,
    :service,
    :created_at,
    :updated_at,
    :published_at,
    :whitelisted_at,
    :hidden_at,
    :closed_at,
    :published_types_de_champ,
    :published_types_de_champ_private,
    :for_individual,
    :auto_archive_on,
    :initiated_mail_template,
    :received_mail_template,
    :closed_mail_template,
    :refused_mail_template,
    :without_continuation_mail_template,
    :attestation_template,
    :procedure_expires_when_termine_enabled,
    :duree_conservation_dossiers_dans_ds,
    :max_duree_conservation_dossiers_dans_ds
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = [
    :procedure_expires_when_termine_enabled,
    :duree_conservation_dossiers_dans_ds,
    :max_duree_conservation_dossiers_dans_ds
  ].freeze

  # Overwrite this method to customize how procedures are displayed
  # across all pages of the admin dashboard.
  #
  def display_resource(procedure)
    "#{procedure.libelle} ##{procedure.id}"
  end
end
