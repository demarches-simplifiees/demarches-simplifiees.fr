# frozen_string_literal: true

require "administrate/base_dashboard"

class InstructeurDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    user: Field::HasOne.with_options(searchable: true, searchable_field: 'email'),
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
    dossiers: Field::HasMany,
    procedures: Field::HasMany,
    bypass_email_login_token: Field::Boolean
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = [
    :id,
    :user,
    :created_at
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = [
    :procedures,
    :dossiers,
    :id,
    :user,
    :created_at,
    :bypass_email_login_token
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = [
    :bypass_email_login_token
  ].freeze

  # Overwrite this method to customize how users are displayed
  # across all pages of the admin dashboard.
  #
  def display_resource(instructeur)
    instructeur.email
  end
end
