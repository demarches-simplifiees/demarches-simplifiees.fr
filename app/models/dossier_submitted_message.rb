# frozen_string_literal: true

class DossierSubmittedMessage < ApplicationRecord
  has_many :revisions, class_name: 'ProcedureRevision', inverse_of: :dossier_submitted_message, dependent: :nullify

  normalizes :message_on_submit_by_usager, with: -> message { message&.strip }
end
