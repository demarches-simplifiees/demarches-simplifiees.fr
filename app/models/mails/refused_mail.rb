# frozen_string_literal: true

# == Schema Information
#
# Table name: refused_mails
#
#  id           :integer          not null, primary key
#  body         :text
#  subject      :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  procedure_id :integer
#
module Mails
  # refuse
  class RefusedMail < ApplicationRecord
    include MailTemplateConcern

    belongs_to :procedure, optional: false

    validates :subject, tags: true
    validates :body, tags: true

    SLUG = "refused_mail"
    DISPLAYED_NAME = 'Accusé de refus du dossier'
    DEFAULT_SUBJECT = 'Votre dossier n° --numéro du dossier-- a été refusé (--libellé démarche--)'
    DOSSIER_STATE = Dossier.states.fetch(:refuse)

    def actions_for_dossier(dossier)
      [MailTemplateConcern::Actions::REPLY, MailTemplateConcern::Actions::SHOW]
    end

    def self.default_template_name_for_procedure(procedure)
      attestation_refus_template = procedure.attestation_refus_template
      if attestation_refus_template&.activated?
        "notification_mailer/default_templates/refused_mail_with_attestation"
      else
        "notification_mailer/default_templates/refused_mail"
      end
    end
  end
end
