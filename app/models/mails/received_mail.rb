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
  class ReceivedMail < ApplicationRecord
    include MailTemplateConcern

    belongs_to :procedure

    SLUG = "received_mail"
    DEFAULT_TEMPLATE_NAME = "notification_mailer/default_templates/received_mail"
    DISPLAYED_NAME = 'Accusé de passage en instruction'
    DEFAULT_SUBJECT = 'Votre dossier nº --numéro du dossier-- va être examiné (--libellé démarche--)'
    DOSSIER_STATE = Dossier.states.fetch(:en_instruction)
  end
end
