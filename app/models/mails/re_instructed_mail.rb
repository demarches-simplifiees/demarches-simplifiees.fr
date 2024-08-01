# frozen_string_literal: true

# == Schema Information
#
# Table name: re_instructed_mails
#
#  id           :integer          not null, primary key
#  body         :text
#  subject      :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  procedure_id :integer
#
module Mails
  class ReInstructedMail < ApplicationRecord
    include MailTemplateConcern

    belongs_to :procedure, optional: false

    validates :subject, tags: true
    validates :body, tags: true

    SLUG = "re_instructed_mail"
    DEFAULT_TEMPLATE_NAME = "notification_mailer/default_templates/re_instructed_mail"
    DISPLAYED_NAME = I18n.t('activerecord.models.mail.re_instructed_mail.under_re_instruction')
    DEFAULT_SUBJECT = I18n.t('activerecord.models.mail.re_instructed_mail.default_subject', dossier_number: '--numéro du dossier--', procedure_libelle: '--libellé démarche--')
    DOSSIER_STATE = Dossier.states.fetch(:en_instruction)
  end
end
