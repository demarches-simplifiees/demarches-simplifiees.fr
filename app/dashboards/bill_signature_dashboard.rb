# frozen_string_literal: true

require "administrate/base_dashboard"

class BillSignatureDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    dossier_operation_logs: Field::HasMany,
    id: Field::Number,
    digest: Field::String,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
    serialized: AttachmentField,
    signature: AttachmentField,
  }.freeze

  COLLECTION_ATTRIBUTES = [
    :id,
    :created_at,
    :dossier_operation_logs,
    :digest,
    :serialized,
    :signature
  ].freeze

  # The show page is disabled, but administrate requires the constant
  # to be defined
  SHOW_PAGE_ATTRIBUTES = [].freeze
end
