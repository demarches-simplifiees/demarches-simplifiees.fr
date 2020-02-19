require "administrate/base_dashboard"

class AdministrateurDashboard < Administrate::BaseDashboard
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
    procedures: Field::HasMany.with_options(limit: 20),
    registration_state: Field::String.with_options(searchable: false),
    current_sign_in_at: Field::DateTime,
    features: FeaturesField,
    email: Field::Email.with_options(searchable: false)
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = [
    :user,
    :created_at,
    :procedures,
    :registration_state
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = [
    :id,
    :user,
    :created_at,
    :updated_at,
    :registration_state,
    :current_sign_in_at,
    :features,
    :procedures
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = [
    :email
  ].freeze

  # Overwrite this method to customize how procedures are displayed
  # across all pages of the admin dashboard.
  #
  def display_resource(administrateur)
    administrateur.email
  end
end
