# frozen_string_literal: true

require "administrate/base_dashboard"

class ServiceDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    type_organisme: Field::String,
    nom: Field::String,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
    administrateur: Field::BelongsTo,
    organisme: Field::String,
    email: Field::String,
    telephone: Field::String,
    horaires: Field::String,
    adresse: Field::String,
    siret: Field::String,
    etablissement_adresse: Field::String.with_options(searchable: false),
    etablissement_latlng: GeopointField
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = [
    :nom,
    :type_organisme
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = [
    :id,
    :type_organisme,
    :nom,
    :created_at,
    :updated_at,
    :administrateur,
    :organisme,
    :email,
    :telephone,
    :horaires,
    :adresse,
    :siret,
    :etablissement_adresse,
    :etablissement_latlng
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = [].freeze

  # Overwrite this method to customize how users are displayed
  # across all pages of the admin dashboard.
  #
  def display_resource(service)
    service.nom
  end
end
