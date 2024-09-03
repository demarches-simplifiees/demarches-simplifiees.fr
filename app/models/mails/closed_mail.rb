# frozen_string_literal: true

# == Schema Information
#
# Table name: closed_mails
#
#  id           :integer          not null, primary key
#  body         :text
#  subject      :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  procedure_id :integer
#
module Mails
  # accepte
  class ClosedMail < ApplicationRecord
    include MailTemplateConcern

    belongs_to :procedure, optional: false

    validates :subject, tags: true
    validates :body, tags: true

    SLUG = "closed_mail"
    DISPLAYED_NAME = "Accusé d’acceptation"
    DEFAULT_SUBJECT = 'Votre dossier nº --numéro du dossier-- a été accepté (--libellé démarche--)'
    DOSSIER_STATE = Dossier.states.fetch(:accepte)

    def self.default_template_name_for_procedure(procedure)
      attestation_template = procedure.attestation_template
      if attestation_template&.activated?
        "notification_mailer/default_templates/closed_mail_with_attestation"
      else
        "notification_mailer/default_templates/closed_mail"
      end
    end
  end
end
