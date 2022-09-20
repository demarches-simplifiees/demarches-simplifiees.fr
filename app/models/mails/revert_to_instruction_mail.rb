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
  class RepasserEnInstructionMail < ApplicationRecord
    include MailTemplateConcern

    belongs_to :procedure, optional: false

    SLUG = "revert_to_instruction"
    DEFAULT_TEMPLATE_NAME = "notification_mailer/default_templates/revert_to_instruction_mail"
    DISPLAYED_NAME = I18n.t('activerecord.models.mail.revert_to_instruction_mail.revert_to_instruction')
    DEFAULT_SUBJECT = I18n.t('activerecord.models.mail.revert_to_instruction_mail.default_subject', dossier_number: '--numéro du dossier--', procedure_libelle: '--libellé démarche--')
    DOSSIER_STATE = Dossier.states.fetch(:en_instruction)
  end
end
