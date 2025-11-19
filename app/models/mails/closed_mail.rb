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
    DISPLAYED_NAME = I18n.t('activerecord.models.mail.closed_mail.acceptance_acknowledgment')
    DEFAULT_SUBJECT = I18n.t('activerecord.models.mail.closed_mail.default_subject', dossier_number: '--numéro du dossier--', procedure_libelle: '--libellé démarche--')
    DOSSIER_STATE = Dossier.states.fetch(:accepte)

    def self.default_template_name_for_procedure(procedure)
      attestation_acceptation_template = procedure.attestation_acceptation_template
      if attestation_acceptation_template&.activated?
        "notification_mailer/default_templates/closed_mail_with_attestation"
      else
        "notification_mailer/default_templates/closed_mail"
      end
    end
  end
end
