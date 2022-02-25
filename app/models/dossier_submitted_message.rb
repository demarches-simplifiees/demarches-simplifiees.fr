# == Schema Information
#
# Table name: dossier_submitted_messages
#
#  id                          :bigint           not null, primary key
#  message_on_submit_by_usager :string
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#
class DossierSubmittedMessage < ApplicationRecord
  has_many :revisions, class_name: 'ProcedureRevision', inverse_of: :dossier_submitted_message, dependent: :nullify
end
