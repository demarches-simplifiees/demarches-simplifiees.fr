class DossierSubmittedMessage < ApplicationRecord
  has_many :revisions, class_name: 'ProcedureRevision', inverse_of: :dossier_submitted_message, dependent: :nullify
end
