# frozen_string_literal: true

# == Schema Information
#
# Table name: received_mails
#
#  id           :integer          not null, primary key
#  body         :text
#  subject      :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  procedure_id :integer
#
module Mails
  # en_instruction
  class ReceivedMail < ApplicationRecord
    include MailTemplateConcern

    belongs_to :procedure, optional: false

    validates :subject, tags: true
    validates :body, tags: true

    SLUG = "received_mail"
    DEFAULT_TEMPLATE_NAME = "notification_mailer/default_templates/received_mail"
    DISPLAYED_NAME = I18n.t('activerecord.models.mail.received_mail.under_instruction')
    DEFAULT_SUBJECT = I18n.t('activerecord.models.mail.received_mail.default_subject', dossier_number: '--numéro du dossier--', procedure_libelle: '--libellé démarche--')
    DOSSIER_STATE = Dossier.states.fetch(:en_instruction)
  end
end
