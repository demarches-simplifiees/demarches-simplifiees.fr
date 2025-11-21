# frozen_string_literal: true

# == Schema Information
#
# Table name: without_continuation_mails
#
#  id           :integer          not null, primary key
#  body         :text
#  subject      :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  procedure_id :integer
#
module Mails
  # classe_sans_suite
  class WithoutContinuationMail < ApplicationRecord
    include MailTemplateConcern

    belongs_to :procedure, optional: false

    validates :subject, tags: true
    validates :body, tags: true

    SLUG = "without_continuation"
    DEFAULT_TEMPLATE_NAME = "notification_mailer/default_templates/without_continuation_mail"
    DISPLAYED_NAME = I18n.t('activerecord.models.mail.without_continuation_mail.closure_acknowledgment')
    DEFAULT_SUBJECT = I18n.t('activerecord.models.mail.without_continuation_mail.default_subject', dossier_number: '--numéro du dossier--', procedure_libelle: '--libellé démarche--')
    DOSSIER_STATE = Dossier.states.fetch(:sans_suite)
  end
end
