require "administrate/base_dashboard"

class TeamAccountDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    email: Field::String,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
    current_sign_in_at: Field::DateTime,
    last_sign_in_at: Field::DateTime,
    dossiers: Field::HasMany,
    procedures: Field::HasMany,
    administrateur: Field::HasOne,
    instructeur: Field::HasOne
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = [
    :email,
    :administrateur,
    :instructeur,
    :last_sign_in_at,
    :current_sign_in_at

  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = [
    :dossiers,
    :procedures,
    :id,
    :email,
    :current_sign_in_at,
    :last_sign_in_at,
    :created_at
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = [].freeze

  # Overwrite this method to customize how users are displayed
  # across all pages of the admin dashboard.
  #
  def display_resource(user)
    user.email
  end
end
