# frozen_string_literal: true

require "administrate/base_dashboard"

class ExportDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    id: Field::Number.with_options(searchable: true),
    file: AttachmentField,
    format: Field::Select.with_options(searchable: false, collection: -> (field) { field.resource.class.send(field.attribute.to_s.pluralize).keys }),
    groupe_instructeurs: IdField,
    job_status: Field::Select.with_options(searchable: false, collection: -> (field) { field.resource.class.send(field.attribute.to_s.pluralize).keys }),
    key: Field::Text,
    procedure_presentation: IdField,
    procedure_presentation_snapshot: Field::String.with_options(searchable: false),
    statut: Field::Select.with_options(searchable: false, collection: -> (field) { field.resource.class.send(field.attribute.to_s.pluralize).keys }),
    time_span_type: Field::Select.with_options(searchable: false, collection: -> (field) { field.resource.class.send(field.attribute.to_s.pluralize).keys }),
    created_at: Field::DateTime.with_options(format: "%d/%m %H:%M:%S"),
    updated_at: Field::DateTime.with_options(format: "%d/%m %H:%M:%S"),
    procedure: IdField
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = [:id, :procedure, :job_status, :created_at, :updated_at].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = [:id, :procedure, :job_status, :format, :statut, :file, :groupe_instructeurs, :key, :procedure_presentation, :procedure_presentation_snapshot, :time_span_type, :created_at, :updated_at].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = [].freeze

  # COLLECTION_FILTERS
  # a hash that defines filters that can be used while searching via the search
  # field of the dashboard.
  #
  # For example to add an option to search for open resources by typing "open:"
  # in the search field:
  #
  #   COLLECTION_FILTERS = {
  #     open: ->(resources) { resources.where(open: true) }
  #   }.freeze
  COLLECTION_FILTERS = {}.freeze

  # Overwrite this method to customize how exports are displayed
  # across all pages of the admin dashboard.
  #
  # def display_resource(export)
  #   "Export ##{export.id}"
  # end
end
